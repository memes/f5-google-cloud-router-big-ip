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
  default     = "cloud-route-poc"
  description = <<EOD
A nonce to uniquely identify the resources created.
EOD
}

variable "num_bigips" {
  type        = number
  default     = 2
  description = <<EOD
The number of BIG-IP instances to create. Default is 2.
EOD
}

variable "bigip_sa" {
  type        = string
  description = <<EOD
The fully-qualified email address of BIG-IP service account.
EOD
}

variable "bigip_image" {
  type        = string
  default     = "projects/f5-7626-networks-public/global/images/f5-bigip-15-1-0-4-0-0-6-payg-good-25mbps-200618231522"
  description = <<EOD
The BIG-IP image to use; default is a v15.1.0.4 PAYG licensed GOOD/25MBps image.
EOD
}

variable "zone" {
  type        = string
  default     = "us-central1-f"
  description = <<EOD
The zone to use for BIG-IP and other resources. Default is 'us-central1-f'.
EOD
}

variable "client_sa" {
  type        = string
  description = <<EOD
The fully-qualified email address of client VMs service account.
EOD
}

variable "service_sa" {
  type        = string
  description = <<EOD
The fully-qualified email address of service VMs service account.
EOD
}

variable "client_subnet" {
  type        = string
  description = <<EOD
A self-link for the client subnet that will host client VMs that will
communicate with service VMs through BIG-IP as an advertised next-hop.
EOD
}

variable "dmz_subnet" {
  type        = string
  description = <<EOD
A self-link for the DMZ subnet that will host BIG-IP external interface.
EOD
}

variable "control_subnet" {
  type        = string
  description = <<EOD
A self-link for the control subnet that will host BIG-IP, client, and service
management interfaces.
EOD
}

variable "service_subnet" {
  type        = string
  description = <<EOD
A self-link for the service subnet that will host BIG-IP internal interface, and
service VMs.
EOD
}

variable "num_clients" {
  type        = number
  default     = 1
  description = <<EOD
The number of client instances to create. Default is 1.
EOD
}

variable "num_services" {
  type        = number
  default     = 2
  description = <<EOD
The number of service instances to create. Default is 2.
EOD
}
