# Cloud Router and F5 BIG-IP

![pre-commit](https://github.com/memes/f5-google-cloud-router-big-ip/workflows/pre-commit/badge.svg)

This repo links two multiple networks together in an approximation of
[Dedicated Interconnect](https://cloud.google.com/network-connectivity/docs/interconnect/concepts/dedicated-overview),
demonstrating how to use Routes and Cloud Router between
VPCs to use BIG-IP as the next-hop gateway.

![HLA](images/f5-google-cloud-router-big-ip.png)

1. Client instance
   * NGINX reverse-proxy configured to send all requests to backend instances in `172.17.0.0/16` network
   * Public IP, with FW rules to allow ingress from public internet
2. Service instances
   * NGINX hosting a static web page
   * No public IP, egress through `control` network only
3. BIG-IP instance
   * 3-NIC configuration, with interfaces in `dmz`, `control`, and `service`
   * Virtual Server defined on VIP(s) with **Service instances** as pool members
   * Forwarding rule defined on *external* interface (`dmz`)
4. `client` and `dmz` networks are connected via HA VPN pair, with Cloud Router advertising routes
   * *client* is advertising `172.16.0.0/16` to *dmz*
   * *dmz* is advertising `172.18.0.0/16` to *client*
   * *dmz* is advertising `172.17.0.0/16` with **next-hop as BIG-IP**

## Setup

1. Create the networking foundations
   See [foundations](/foundations) module for example setup
2. Create/modify the Terraform environment files with required [inputs](#inputs)
3. Execute Terraform to create the BIG-IP instance and Route
   **NOTE:** due to weak module dependencies, you may need to invoke this step as
   in two parts so that the dependent address is known.

   ```shell
   terraform init -backend-config env/ENV/poc.config
   terraform apply -var-file env/ENV/poc.tfvars -auto-approve -target module.bigip
   terraform apply -var-file env/ENV/poc.tfvars -auto-approve
   ```

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
| random | n/a |
| terraform | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bigip\_image | The BIG-IP image to use; default is a v15.1.0.4 PAYG licensed GOOD/25MBps image. | `string` | `"projects/f5-7626-networks-public/global/images/f5-bigip-15-1-0-4-0-0-6-payg-good-25mbps-200618231522"` | no |
| bigip\_vip | The IP address to set as the BIG-IP VIP. If left blank (default), a value will<br>be chosen from the `dmz_cidr` block. | `string` | `""` | no |
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
