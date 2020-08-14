# Use this file to set Terraform variables for Cloud Router and BIG-IP deployment in 4138
project_id  = "f5-gcs-4138-sales-cloud-sales"
tf_sa_email = "terraform@f5-gcs-4138-sales-cloud-sales.iam.gserviceaccount.com"
nonce       = "emes-poc"
# The GCS bucket and prefix to retrieve foundations state used in this POC
foundations_tf_state_bucket = "tf-f5-gcs-4138-sales-cloud-sales"
foundations_tf_state_prefix = "emes/cloud-router/foundations"
