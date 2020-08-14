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

# Provider and Terraform service acocunt impersonation is handled in providers.tf

# Create the service accounts to be used in the project
module "service_accounts" {
  source     = "terraform-google-modules/service-accounts/google"
  version    = "2.0.2"
  project_id = var.project_id
  prefix     = var.nonce
  names      = ["client", "service", "bigip"]
  project_roles = [
    "${var.project_id}=>roles/logging.logWriter",
    "${var.project_id}=>roles/monitoring.metricWriter",
    "${var.project_id}=>roles/monitoring.viewer"
  ]
  generate_keys = false
}

locals {
  region = replace(var.bastion_zone, "/-[a-z]$/", "")
}

# This network represents the upstream network that will be routed through
# Cloud Router to BIG-IP instances
module "client" {
  source       = "terraform-google-modules/network/google"
  version      = "2.5.0"
  project_id   = var.project_id
  network_name = format(var.client_network_name_template, var.nonce)
  subnets = [
    {
      subnet_name                            = "client"
      subnet_ip                              = var.client_cidr
      subnet_region                          = local.region
      delete_default_internet_gateway_routes = true
      subnet_private_access                  = true
    }
  ]
}

# This network represents the data-plane shared by BIG-IP and target service
# VMs
module "service" {
  source       = "terraform-google-modules/network/google"
  version      = "2.5.0"
  project_id   = var.project_id
  network_name = format(var.service_network_name_template, var.nonce)
  subnets = [
    {
      subnet_name                            = "service"
      subnet_ip                              = var.service_cidr
      subnet_region                          = local.region
      delete_default_internet_gateway_routes = true
      subnet_private_access                  = true
    }
  ]
  /*
  routes = [
    {
      name = format("%s-proxy-bigip", var.nonce)
      description = format("Force next-hop to BIG-IP VIP for server CIDR")
      destination_range = cidrsubnet(var.service_cidr, 2, 3)
      next_hop_ip = cidrhost(cidrsubnet(var.service_cidr, 2, 2), 0)
    }
  ]
  */
}

# This represents the control/management network in a BIG-IP two NIC deployment
module "control" {
  source       = "terraform-google-modules/network/google"
  version      = "2.5.0"
  project_id   = var.project_id
  network_name = format(var.control_network_name_template, var.nonce)
  subnets = [
    {
      subnet_name                            = "control"
      subnet_ip                              = var.control_cidr
      subnet_region                          = local.region
      delete_default_internet_gateway_routes = false
      subnet_private_access                  = true
    }
  ]
}

# Create a NAT gateway on the control-plane network
module "control-nat" {
  source                             = "terraform-google-modules/cloud-nat/google"
  version                            = "~> 1.3.0"
  project_id                         = var.project_id
  region                             = local.region
  name                               = format(var.nat_name_template, var.nonce)
  router                             = format(var.nat_name_template, var.nonce)
  create_router                      = true
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  network                            = module.control.network_self_link
  subnetworks = [
    {
      name                     = "control"
      source_ip_ranges_to_nat  = ["ALL_IP_RANGES"]
      secondary_ip_range_names = []
    },
  ]
}

module "bastion" {
  source                     = "terraform-google-modules/bastion-host/google"
  version                    = "2.7.0"
  service_account_name       = format(var.bastion_name_template, var.nonce)
  name                       = format(var.bastion_name_template, var.nonce)
  name_prefix                = format(var.bastion_name_template, var.nonce)
  fw_name_allow_ssh_from_iap = format("%s-allow-iap-ssh-bastion", var.nonce)
  project                    = var.project_id
  network                    = module.control.network_self_link
  subnet                     = lookup(lookup(module.control.subnets, format("%s/control", local.region), {}), "self_link", "")
  zone                       = var.bastion_zone
  members                    = var.bastion_access_members
  # Default Bastion instance is CentOS; install tinyproxy from EPEL
  startup_script = <<EOD
#!/bin/sh
yum install -y epel-release
yum install -y tinyproxy
systemctl daemon-reload
systemctl stop tinyproxy
# Enable reverse proxy only mode and allow access from all sources; IAP is
# enforcing access to the VM.
sed -i -e '/^#\?ReverseOnly/cReverseOnly Yes' \
    -e '/^Allow /d' \
    /etc/tinyproxy/tinyproxy.conf
systemctl enable tinyproxy
systemctl start tinyproxy
EOD
}

# Allow bastion to all on control-plane
resource "google_compute_firewall" "bastion_control_plane" {
  project     = var.project_id
  name        = format("%s-allow-bastion-control-plane", var.nonce)
  network     = module.control.network_self_link
  description = format("Allow bastion to all control-plane ingress (%s)", var.nonce)
  direction   = "INGRESS"
  source_service_accounts = [
    module.bastion.service_account,
  ]
  target_service_accounts = [
    module.service_accounts.emails["bigip"],
    module.service_accounts.emails["service"],
  ]
  allow {
    protocol = "all"
  }
}
