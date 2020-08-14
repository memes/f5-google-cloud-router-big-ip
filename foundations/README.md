# Foundations

This Terraform module creates a set of service accounts and foundational
resources that would typically be provided by a Project Factory.

<!-- markdownlint-disable no-inline-html -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 0.12 |
| google | ~> 3.34 |
| google | ~> 3.34 |

## Providers

| Name | Version |
|------|---------|
| google | ~> 3.34 ~> 3.34 |
| google.executor | ~> 3.34 ~> 3.34 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bastion\_access\_members | An optional list of users/groups/serviceAccounts that can login to the control-plane<br>bastion via IAP tunnelling. Default is an empty list. | `list(string)` | `[]` | no |
| bastion\_name\_template | The naming template for bastion VMs and service account; default is '%s-bastion'. | `string` | `"%s-bastion"` | no |
| bastion\_zone | The zone to use for bastion VM. The subnets will be created in the region for<br>this zone. Default is 'us-central1-f'. | `string` | `"us-central1-f"` | no |
| client\_cidr | The CIDR to used for the upstream client subnet created in `zone`. Default is<br>'172.16.0.0/16'. | `string` | `"172.16.0.0/16"` | no |
| client\_network\_name\_template | The naming template for the upstream client network to create; default is '%s-client'. | `string` | `"%s-client"` | no |
| control\_cidr | The CIDR to use for control-plane BIG-IP nics and bastion host. | `string` | `"192.168.0.0/24"` | no |
| control\_network\_name\_template | The naming temaplte for the control-plane network to create; default is<br>'%s-control'. | `string` | `"%s-control"` | no |
| nat\_name\_template | The naming template for Cloud NAT and Router; default is '%s-control-nat'. | `string` | `"%s-control-nat"` | no |
| nonce | The name of the upstream client network to create; default is 'client'. | `string` | n/a | yes |
| project\_id | The existing project id that will host the resources. E.g.<br>project\_id = "example-project-id" | `string` | n/a | yes |
| service\_cidr | The CIDR to use for services subnet created in `zone`. Default is '172.17.0.0/16'. | `string` | `"172.17.0.0/16"` | no |
| service\_network\_name\_template | The naming template for the services network to create; default is '%s-service'. | `string` | `"%s-service"` | no |
| tf\_sa\_email | The fully-qualified email address of the Terraform service account to use for<br>resource creation. E.g.<br>tf\_sa\_email = "terraform@PROJECT\_ID.iam.gserviceaccount.com" | `string` | n/a | yes |
| tf\_sa\_token\_lifetime\_secs | The expiration duration for the service account token, in seconds. This value<br>should be high enough to prevent token timeout issues during resource creation,<br>but short enough that the token is useless replayed later. Default value is 1200. | `number` | `1200` | no |

## Outputs

| Name | Description |
|------|-------------|
| bastion\_name | The name of the bastion VM. |
| bigip\_sa | The fully-qualified email address of BIG-IP service account. |
| client\_network | The client network self-link. |
| client\_sa | The fully-qualified email address of client service account. |
| client\_subnet | The client subnet self-link. |
| control\_network | The control network self-link. |
| control\_subnet | The control subnet self-link. |
| service\_network | The service network self-link. |
| service\_sa | The fully-qualified email address of service service account. |
| service\_subnet | The service subnet self-link. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- markdownlint-enable no-inline-html -->
