# Changelog

## v1.1.0 - VPC peering

* Replace VPN HA pair with VPC Peering
* Decouple Terraform from [foundations](/foundations) state
  * Variables for service accounts, subnet self-links are required
* Modify AS3 to forward to `service` VMs
* Modified target HTML to include BIG-IP internal address in response
* Renamed `f5-sales` example Terraform configurations to `emes-poc`

## v1.0.0 - BIG-IP as next-hop

* Cloud Routes advertising `service` subnet CIDR via BIG-IP next-hop
* Client instances only see `dmz` subnet directly

## v0.0.1 - Limited CIDR advertisement

* Demo use of restricted CIDR advertisements so that only BIG-IP VIP (alias IPs) are visible to client instances
