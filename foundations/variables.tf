variable "tf_sa_email" {
  type        = string
  description = <<EOD
The fully-qualified email address of the Terraform service account to use for
resource creation. E.g.
tf_sa_email = "terraform@PROJECT_ID.iam.gserviceaccount.com"
EOD
}

variable "tf_sa_token_lifetime_secs" {
  type        = number
  default     = 1200
  description = <<EOD
The expiration duration for the service account token, in seconds. This value
should be high enough to prevent token timeout issues during resource creation,
but short enough that the token is useless replayed later. Default value is 1200.
EOD
}

variable "project_id" {
  type        = string
  description = <<EOD
The existing project id that will host the resources. E.g.
project_id = "example-project-id"
EOD
}

variable "nonce" {
  type        = string
  description = <<EOD
The name of the upstream client network to create; default is 'client'.
EOD
}

variable "client_network_name_template" {
  type        = string
  default     = "%s-client"
  description = <<EOD
The naming template for the upstream client network to create; default is '%s-client'.
EOD
}

variable "client_cidr" {
  type        = string
  default     = "172.16.0.0/16"
  description = <<EOD
The CIDR to used for the upstream client subnet created in `zone`. Default is
'172.16.0.0/16'.
EOD
}

variable "service_network_name_template" {
  type        = string
  default     = "%s-service"
  description = <<EOD
The naming template for the services network to create; default is '%s-service'.
EOD
}

variable "service_cidr" {
  type        = string
  default     = "172.17.0.0/16"
  description = <<EOD
The CIDR to use for services subnet created in `zone`. Default is '172.17.0.0/16'.
EOD
}

variable "control_network_name_template" {
  type        = string
  default     = "%s-control"
  description = <<EOD
The naming temaplte for the control-plane network to create; default is
'%s-control'.
EOD
}

variable "control_cidr" {
  type        = string
  default     = "192.168.0.0/24"
  description = <<EOD
The CIDR to use for control-plane BIG-IP nics and bastion host.
EOD
}

variable "nat_name_template" {
  type        = string
  default     = "%s-control-nat"
  description = <<EOD
The naming template for Cloud NAT and Router; default is '%s-control-nat'.
EOD
}

variable "bastion_name_template" {
  type        = string
  default     = "%s-bastion"
  description = <<EOD
The naming template for bastion VMs and service account; default is '%s-bastion'.
EOD
}

variable "bastion_access_members" {
  type        = list(string)
  default     = []
  description = <<EOD
An optional list of users/groups/serviceAccounts that can login to the control-plane
bastion via IAP tunnelling. Default is an empty list.
EOD
}

variable "bastion_zone" {
  type        = string
  default     = "us-central1-f"
  description = <<EOD
The zone to use for bastion VM. The subnets will be created in the region for
this zone. Default is 'us-central1-f'.
EOD
}

variable "dmz_network_name_template" {
  type        = string
  default     = "%s-dmz"
  description = <<EOD
The naming template for the services network to create; default is '%s-dmz'.
EOD
}

variable "dmz_cidr" {
  type        = string
  default     = "172.18.0.0/16"
  description = <<EOD
The CIDR to use for services subnet created in `zone`. Default is '172.18.0.0/16'.
EOD
}
