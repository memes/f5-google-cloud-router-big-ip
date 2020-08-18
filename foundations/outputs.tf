output "bastion_name" {
  value       = module.bastion.hostname
  description = <<EOD
The name of the bastion VM.
EOD
}

output "client_sa" {
  value       = module.service_accounts.emails["client"]
  description = <<EOD
The fully-qualified email address of client dmz account.
EOD
}

output "bigip_sa" {
  value       = module.service_accounts.emails["bigip"]
  description = <<EOD
The fully-qualified email address of BIG-IP service account.
EOD
}

output "service_sa" {
  value       = module.service_accounts.emails["service"]
  description = <<EOD
The fully-qualified email address of service service account.
EOD
}

output "client_network" {
  value       = module.client.network_self_link
  description = <<EOD
The client network self-link.
EOD
}

output "client_subnet" {
  value       = lookup(lookup(module.client.subnets, format("%s/client", local.region), {}), "self_link", "")
  description = <<EOD
The client subnet self-link.
EOD
}

output "service_network" {
  value       = module.service.network_self_link
  description = <<EOD
The service network self-link.
EOD
}

output "service_subnet" {
  value       = lookup(lookup(module.service.subnets, format("%s/service", local.region), {}), "self_link", "")
  description = <<EOD
The service subnet self-link.
EOD
}

output "control_network" {
  value       = module.control.network_self_link
  description = <<EOD
The control network self-link.
EOD
}

output "control_subnet" {
  value       = lookup(lookup(module.control.subnets, format("%s/control", local.region), {}), "self_link", "")
  description = <<EOD
The control subnet self-link.
EOD
}

output "dmz_network" {
  value       = module.dmz.network_self_link
  description = <<EOD
The DMZ network self-link.
EOD
}

output "dmz_subnet" {
  value       = lookup(lookup(module.dmz.subnets, format("%s/dmz", local.region), {}), "self_link", "")
  description = <<EOD
The DMZ subnet self-link.
EOD
}
