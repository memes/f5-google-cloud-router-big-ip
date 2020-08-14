output "bigip_control_plane_ips" {
  value       = [for address in module.bigip.management_addresses : replace(address, "/\\/32$/", "")]
  description = <<EOD
The collective set of IP addresses that are assigned to BIG-IP instances
attached to the control-plane subnet.
EOD
}

output "bigip_vips" {
  value       = [local.bigip_vip]
  description = <<EOD
The data-plane VIP addresses assigned to BIG-IP.
EOD
}

output "client_public_ips" {
  value       = compact(flatten([for vm in google_compute_instance.client : [for ac in vm.network_interface[0].access_config : ac.nat_ip]]))
  description = <<EOD
The public IP addresses for the client instances.
EOD
}
