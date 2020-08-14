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
A nonce to uniquely identify the resources created.
EOD
}
variable "foundations_tf_state_bucket" {
  type        = string
  description = <<EOD
The name of a GCS bucket containing the Terraform state for foundational resources.
EOD
}

variable "foundations_tf_state_prefix" {
  type        = string
  description = <<EOD
The prefix to the foundational Terraform state files.
EOD
}

variable "num_bigips" {
  type        = number
  default     = 1
  description = <<EOD
The number of BIG-IP instances to create. Default is 1.
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

variable "bigip_vip" {
  type        = string
  default     = ""
  description = <<EOD
The IP address to set as the BIG-IP VIP. If left blank (default), a value will
be chosen from the `external_cidr` block.
EOD
}
