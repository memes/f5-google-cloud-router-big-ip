# This module has been tested with Terraform 0.12.x only.
#
# Note: GCS backend requires the current user to have valid application-default
# credentials. An error like "... failed: dialing: google: could not find default
# credenitals" indicates that the calling user must (re-)authenticate application
# default credentials using `gcloud auth application-default login`.
terraform {
  required_version = "~> 0.12"
  # The location and path for GCS state storage must be specified in an environment
  # file(s) via `-backend-config env/NAME/base.config`
  backend "gcs" {}
}

# Provider and Terraform service account impersonation is handled in providers.tf

# Retrieve foundations outputs from GCS backend; in TFE/Cloud this would be of
# type 'remote'.
data "terraform_remote_state" "foundations" {
  backend = "gcs"
  config = {
    bucket = var.foundations_tf_state_bucket
    prefix = var.foundations_tf_state_prefix
  }
}

# Get details on the client subnet
data "google_compute_subnetwork" "client" {
  self_link = data.terraform_remote_state.foundations.outputs.client_subnet
}

# Get details on the service subnet
data "google_compute_subnetwork" "service" {
  self_link = data.terraform_remote_state.foundations.outputs.service_subnet
}

# Get details on the control subnet
data "google_compute_subnetwork" "control" {
  self_link = data.terraform_remote_state.foundations.outputs.control_subnet
}

locals {
  # For simplicity all resources use a single zone; grok the region from the zone.
  region = replace(var.zone, "/-[a-z]$/", "")
  # Choose a BIG-IP VIP address, if not provided, as 5th /28 in the service
  # subnet CIDR allocation
  bigip_vip = coalesce(var.bigip_vip, cidrsubnet(data.google_compute_subnetwork.service.ip_cidr_range, 12, 5))
}

# Create a VPN link from client network to service
module "vpn_client" {
  source           = "terraform-google-modules/vpn/google//modules/vpn_ha"
  version          = "~> 1.3.0"
  project_id       = var.project_id
  region           = local.region
  network          = data.google_compute_subnetwork.client.network
  name             = format("%s-client-to-service", var.nonce)
  peer_gcp_gateway = module.vpn_service.self_link
  router_asn       = 65501
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = 65502
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.1.2/30"
      ike_version                     = 2
      vpn_gateway_interface           = 0
      peer_external_gateway_interface = null
      shared_secret                   = ""
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = 65502
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.2.2/30"
      ike_version                     = 2
      vpn_gateway_interface           = 1
      peer_external_gateway_interface = null
      shared_secret                   = ""
    }
  }
}

# Create a VPN link from service network to client
module "vpn_service" {
  source           = "terraform-google-modules/vpn/google//modules/vpn_ha"
  version          = "~> 1.3.0"
  project_id       = var.project_id
  region           = local.region
  network          = data.google_compute_subnetwork.service.network
  name             = format("%s-service-to-client", var.nonce)
  router_asn       = 65502
  peer_gcp_gateway = module.vpn_client.self_link
  # Only advertise the CIDR used by BIG-IP VIP(s)
  router_advertise_config = {
    mode   = "CUSTOM"
    groups = []
    ip_ranges = {
      tostring(local.bigip_vip) = format("BIG-IP %s", var.nonce)
    }
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.2"
        asn     = 65501
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.1.1/30"
      ike_version                     = 2
      vpn_gateway_interface           = 0
      peer_external_gateway_interface = null
      shared_secret                   = module.vpn_client.random_secret
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.2"
        asn     = 65501
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.2.1/30"
      ike_version                     = 2
      vpn_gateway_interface           = 1
      peer_external_gateway_interface = null
      shared_secret                   = module.vpn_client.random_secret
    }
  }
}

# BIG-IP admin password will be randomised for each run
resource "random_password" "admin_password" {
  length  = 16
  special = true
}

# Create a slot for BIG-IP admin password in Secret Manager
resource "google_secret_manager_secret" "admin_password" {
  project   = var.project_id
  secret_id = format("bigip-admin-passwd-key-%s", var.nonce)
  replication {
    automatic = true
  }
}

# Store the BIG-IP password in the Secret Manager
resource "google_secret_manager_secret_version" "admin_password" {
  secret      = google_secret_manager_secret.admin_password.id
  secret_data = random_password.admin_password.result
}

# Allow the supplied accounts to read the BIG-IP password from Secret Manager
resource "google_secret_manager_secret_iam_member" "admin_password" {
  for_each = toset(formatlist("serviceAccount:%s", [
    data.terraform_remote_state.foundations.outputs.bigip_sa,
  ]))
  project   = var.project_id
  secret_id = google_secret_manager_secret.admin_password.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = each.value
}

module "bigip" {
  #source = "git::https://github.com/memes/f5-google-terraform-modules//modules/big-ip/ha?ref=1.0.1"
  source                 = "/Users/emes/projects/automation/f5-google-terraform-modules//modules/big-ip/instance"
  project_id             = var.project_id
  num_instances          = var.num_bigips
  instance_name_template = format("%s-bigip-%%02d", var.nonce)
  service_account        = data.terraform_remote_state.foundations.outputs.bigip_sa
  image                  = var.bigip_image
  zone                   = var.zone
  # Egress NAT is on control-plane - make sure BIG-IP uses the control-plane
  # subnet gateway for onboarding
  default_gateway = "$MGMT_GATEWAY"
  # Tell BIG-IP boot scritps which Secret Manager key contains the password to
  # use for Admin account
  admin_password_secret_manager_key = google_secret_manager_secret.admin_password.secret_id
  # Assign external (nic0) to the data-plane subnet; use an emphemeral IP address
  external_subnetwork = data.google_compute_subnetwork.service.self_link
  # Define the VIP that will be used
  external_subnetwork_vip_cidrs = [[local.bigip_vip]]
  # Don't need a public IP on external network
  provision_external_public_ip = false
  # Assign management (nic1) to the control-plane subnet; use an emphemeral IP address
  management_subnetwork = data.google_compute_subnetwork.control.self_link
  # Don't need a public IP on management network
  provision_management_public_ip = false
  # Define an app to proxy to services
  as3_payloads = [base64gzip(templatefile("${path.module}/templates/as3.json", {
    vips    = [local.bigip_vip],
    servers = [for vm in google_compute_instance.service : vm.network_interface[0].network_ip],
  }))]
  # BIG-IP v15.1? Cloud-init? Yes,please
  use_cloud_init = true
}

# Launch VMs to represent services behind BIG-IP
resource "google_compute_instance" "service" {
  count       = 2
  project     = var.project_id
  name        = format("%s-service-%02d", var.nonce, count.index)
  description = format("%s service instance", var.nonce)
  zone        = var.zone

  metadata = {
    enable-oslogin = "TRUE"
    user-data = templatefile("${path.module}/templates/service_cloud_config.yml", {
      control_gw = cidrhost(data.google_compute_subnetwork.control.ip_cidr_range, 1)
    })
  }

  machine_type = "n1-standard-1"
  service_account {
    email = data.terraform_remote_state.foundations.outputs.service_sa
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  boot_disk {
    auto_delete = true
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  # Attach nic0 to service network without a public IP
  network_interface {
    subnetwork         = data.google_compute_subnetwork.service.name
    subnetwork_project = data.google_compute_subnetwork.service.project
  }

  # Attach nic1 to control network without a public IP
  network_interface {
    subnetwork         = data.google_compute_subnetwork.control.name
    subnetwork_project = data.google_compute_subnetwork.control.project
  }

  lifecycle {
    create_before_destroy = false
  }
}

# Launch client(s) in the client network; these represent the external
# connections that will be handled by Cloud Router
resource "google_compute_instance" "client" {
  count       = 1
  project     = var.project_id
  name        = format("%s-client-%02d", var.nonce, count.index)
  description = format("%s client instance", var.nonce)
  zone        = var.zone

  metadata = {
    enable-oslogin = "TRUE"
    user-data = templatefile("${path.module}/templates/client_cloud_config.yml", {
      bigip_vip = local.bigip_vip
    })
  }

  machine_type = "n1-standard-1"
  service_account {
    email = data.terraform_remote_state.foundations.outputs.client_sa
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  boot_disk {
    auto_delete = true
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  # Attach nic0 to client network with a public IP for testing
  network_interface {
    subnetwork         = data.google_compute_subnetwork.client.name
    subnetwork_project = data.google_compute_subnetwork.client.project
    access_config {}
  }

  lifecycle {
    create_before_destroy = false
  }
}
