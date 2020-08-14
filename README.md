# Cloud Router and F5 BIG-IP

![pre-commit](https://github.com/memes/f5-cloud-router-big-ip/workflows/pre-commit/badge.svg)

<!-- markdownlint-disable no-inline-html -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 0.12 |
| google | ~> 3.34 |
| google | ~> 3.34 |
| google-beta | ~> 3.34 |

## Providers

| Name | Version |
|------|---------|
| google | ~> 3.34 ~> 3.34 |
| google.executor | ~> 3.34 ~> 3.34 |
| random | n/a |
| terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bigip\_image | The BIG-IP image to use; default is a v15.1.0.4 PAYG licensed GOOD/25MBps image. | `string` | `"projects/f5-7626-networks-public/global/images/f5-bigip-15-1-0-4-0-0-6-payg-good-25mbps-200618231522"` | no |
| bigip\_vip | The IP address to set as the BIG-IP VIP. If left blank (default), a value will<br>be chosen from the `external_cidr` block. | `string` | `""` | no |
| foundations\_tf\_state\_bucket | The name of a GCS bucket containing the Terraform state for foundational resources. | `string` | n/a | yes |
| foundations\_tf\_state\_prefix | The prefix to the foundational Terraform state files. | `string` | n/a | yes |
| nonce | A nonce to uniquely identify the resources created. | `string` | n/a | yes |
| num\_bigips | The number of BIG-IP instances to create. Default is 1. | `number` | `1` | no |
| project\_id | The existing project id that will host the resources. E.g.<br>project\_id = "example-project-id" | `string` | n/a | yes |
| tf\_sa\_email | The fully-qualified email address of the Terraform service account to use for<br>resource creation. E.g.<br>tf\_sa\_email = "terraform@PROJECT\_ID.iam.gserviceaccount.com" | `string` | n/a | yes |
| tf\_sa\_token\_lifetime\_secs | The expiration duration for the service account token, in seconds. This value<br>should be high enough to prevent token timeout issues during resource creation,<br>but short enough that the token is useless replayed later. Default value is 1200. | `number` | `1200` | no |
| zone | The zone to use for BIG-IP and other resources. Default is 'us-central1-f'. | `string` | `"us-central1-f"` | no |

## Outputs

| Name | Description |
|------|-------------|
| bigip\_control\_plane\_ips | The collective set of IP addresses that are assigned to BIG-IP instances<br>attached to the control-plane subnet. |
| bigip\_vips | The data-plane VIP addresses assigned to BIG-IP. |
| client\_public\_ips | The public IP addresses for the client instances. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- markdownlint-enable no-inline-html -->
