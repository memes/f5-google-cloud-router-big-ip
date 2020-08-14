# Defines the firewall rules

# Allow open access to client(s) on port 80
resource "google_compute_firewall" "client_http" {
  project     = var.project_id
  name        = format("%s-allow-client-http-ingress", var.nonce)
  network     = data.google_compute_subnetwork.client.network
  description = format("Allow HTTP ingress to client (%s)", var.nonce)
  direction   = "INGRESS"
  source_ranges = [
    "0.0.0.0/0",
  ]
  target_service_accounts = [
    data.terraform_remote_state.foundations.outputs.client_sa,
  ]
  allow {
    protocol = "tcp"
    ports = [
      80,
      22,
    ]
  }
}

# Only allow ingress to BIG-IP VIP from client network
resource "google_compute_firewall" "bigip_ingress" {
  project     = var.project_id
  name        = format("%s-allow-client-bigip-ingress", var.nonce)
  network     = data.google_compute_subnetwork.service.network
  description = format("Allow HTTP from client CIDR to BIG-IP (%s)", var.nonce)
  direction   = "INGRESS"
  source_ranges = [
    data.google_compute_subnetwork.client.ip_cidr_range,
  ]
  target_service_accounts = [
    data.terraform_remote_state.foundations.outputs.bigip_sa,
  ]
  allow {
    protocol = "tcp"
    ports = [
      80,
    ]
  }
}

# Only allow ingress to service instances from BIG-IP VMs
resource "google_compute_firewall" "bigip_service" {
  project     = var.project_id
  name        = format("%s-allow-bigip-service-ingress", var.nonce)
  network     = data.google_compute_subnetwork.service.network
  description = format("Allow all from BIG-IP to service (%s)", var.nonce)
  direction   = "INGRESS"
  source_service_accounts = [
    data.terraform_remote_state.foundations.outputs.bigip_sa,
  ]
  target_service_accounts = [
    data.terraform_remote_state.foundations.outputs.service_sa,
  ]
  allow {
    protocol = "all"
  }
}
