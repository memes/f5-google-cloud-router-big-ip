# Use this file to set Terraform variables for Cloud Router and BIG-IP deployment in 4138
project_id     = "f5-gcs-4138-sales-cloud-sales"
tf_sa_email    = "terraform@f5-gcs-4138-sales-cloud-sales.iam.gserviceaccount.com"
nonce          = "emes-poc"
num_bigips     = 2
bigip_sa       = "emes-poc-bigip@f5-gcs-4138-sales-cloud-sales.iam.gserviceaccount.com"
client_sa      = "emes-poc-client@f5-gcs-4138-sales-cloud-sales.iam.gserviceaccount.com"
service_sa     = "emes-poc-service@f5-gcs-4138-sales-cloud-sales.iam.gserviceaccount.com"
client_subnet  = "https://www.googleapis.com/compute/v1/projects/f5-gcs-4138-sales-cloud-sales/regions/us-central1/subnetworks/client"
control_subnet = "https://www.googleapis.com/compute/v1/projects/f5-gcs-4138-sales-cloud-sales/regions/us-central1/subnetworks/control"
dmz_subnet     = "https://www.googleapis.com/compute/v1/projects/f5-gcs-4138-sales-cloud-sales/regions/us-central1/subnetworks/dmz"
service_subnet = "https://www.googleapis.com/compute/v1/projects/f5-gcs-4138-sales-cloud-sales/regions/us-central1/subnetworks/service"
