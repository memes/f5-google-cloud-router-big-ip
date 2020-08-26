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

# Get details on the client subnet
data "google_compute_subnetwork" "client" {
  self_link = var.client_subnet
}

# Get details on the service subnet
data "google_compute_subnetwork" "service" {
  self_link = var.service_subnet
}

# Get details on the control subnet
data "google_compute_subnetwork" "control" {
  self_link = var.control_subnet
}

# Get details on the DMZ subnet
data "google_compute_subnetwork" "dmz" {
  self_link = var.dmz_subnet
}

locals {
  # For simplicity all resources use a single zone; grok the region from the zone.
  region = replace(var.zone, "/-[a-z]$/", "")
}

# Reserve IPs on DMZ subnet for BIG-IP nic0s
resource "google_compute_address" "bigip" {
  count        = var.num_bigips
  project      = var.project_id
  name         = format("%s-bigip-ext-%d", var.nonce, count.index)
  subnetwork   = var.dmz_subnet
  address_type = "INTERNAL"
  region       = local.region
}

# Add a route to service subnet with BIG-IP reserved addresses as next hop
# E.g. if two BIG-IPs are created, two custom routes will be added to the DMZ
# network with identical metrics; GCP will use ECMP to determine route to use.
module "routes" {
  source       = "terraform-google-modules/network/google//modules/routes"
  version      = "~> 2.0.0"
  project_id   = var.project_id
  network_name = data.google_compute_subnetwork.dmz.network
  routes = [for i, r in google_compute_address.bigip : {
    name              = format("%s-proxy-bigip-%d", var.nonce, i)
    description       = format("Force next-hop to BIG-IP %d for server CIDR", i)
    destination_range = data.google_compute_subnetwork.service.ip_cidr_range
    # Next hop is nic0 address of BIG-IP VM
    next_hop_ip = r.address
  }]
}

# Create a VPC Peer between client and DMZ networks, advertising the custom
# route defined above
module "peer" {
  source                     = "terraform-google-modules/network/google//modules/network-peering"
  prefix                     = var.nonce
  local_network              = data.google_compute_subnetwork.dmz.network
  peer_network               = data.google_compute_subnetwork.client.network
  export_local_custom_routes = true
}

# BIG-IP admin password will be randomised for each run
resource "random_password" "admin_password" {
  length  = 16
  special = true
  # Exclude shell-special chars from generated password
  override_special = "#%&*()-_=+[]:?,."
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

# Allow the BIG-IP service account to read admin password from Secret Manager
resource "google_secret_manager_secret_iam_member" "admin_password" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.admin_password.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = format("serviceAccount:%s", var.bigip_sa)
}

# Launch BIG-IP as standalone instances
module "bigip" {
  source                 = "git::https://github.com/memes/f5-google-terraform-modules//modules/big-ip/instance?ref=1.0.2"
  project_id             = var.project_id
  num_instances          = var.num_bigips
  instance_name_template = format("%s-bigip-%%02d", var.nonce)
  service_account        = var.bigip_sa
  image                  = var.bigip_image
  zone                   = var.zone
  # Egress NAT is on control-plane - make sure BIG-IP uses the control-plane
  # subnet gateway for onboarding
  default_gateway = "$MGMT_GATEWAY"
  # Tell BIG-IP boot scritps which Secret Manager key contains the password to
  # use for Admin account
  admin_password_secret_manager_key = google_secret_manager_secret.admin_password.secret_id
  # Assign external (nic0) to the DMZ subnet; use an emphemeral IP address
  external_subnetwork = var.dmz_subnet
  # Use the reserved IPs for nic0s
  external_subnetwork_network_ips = [for ip in google_compute_address.bigip : ip.address]
  # Don't need a public IP on external network
  provision_external_public_ip = false
  # Assign management (nic1) to the control-plane subnet; use an emphemeral IP address
  management_subnetwork = var.control_subnet
  # Don't need a public IP on management network
  provision_management_public_ip = false
  # Assign internal (nic2) to services subnet; use an emphemeral IP address
  internal_subnetworks = [var.service_subnet]
  # Don't need a public IP on internal network
  provision_internal_public_ip = false
  # Define an AS3 configuration for each BIG-IP; the declarations are the identical
  as3_payloads = [for i in range(0, var.num_bigips) : base64gzip(templatefile("${path.module}/templates/as3.json", {
    servers = [for vm in google_compute_instance.service : vm.network_interface[0].network_ip]
  }))]
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
    email = var.service_sa
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
    subnetwork = var.service_subnet
  }

  # Attach nic1 to control network without a public IP
  network_interface {
    subnetwork = var.control_subnet
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
      targets = [for vm in google_compute_instance.service : vm.network_interface[0].network_ip]
    })
  }

  machine_type = "n1-standard-1"
  service_account {
    email = var.client_sa
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
    subnetwork = var.client_subnet
    access_config {}
  }

  lifecycle {
    create_before_destroy = false
  }
}
