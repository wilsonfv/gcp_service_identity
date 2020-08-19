# Introduction
To test whether we could use a gcp service account to create service identity, typically it's to use gcp service account to run these commands
```
gcloud beta services identity create --service=sqladmin.googleapis.com \
    --project=${GCP_PROJECT_ID}
gcloud beta services identity create --service=servicenetworking.googleapis.com \
    --project=${GCP_PROJECT_ID}
```

# Prerequisites
* gcp user account with roles `roles/editor` and `roles/iam.securityAdmin` in a gcp project
* gcloud sdk

# Instruction
Run [test_gcp_service_identity.sh](test_gcp_service_identity.sh) <br/>
The script assumes you have correct gcp user account and gcp project id setup in your local gcloud config. <br/>
The script will 
* create a gcp service account 
* before any role assigned to the gcp service account, run above 2 commands to create service identity
* after assign proper roles to the gcp service account, run above 2 commands again to create service identity
* clean up

# Conclusion
See output of the script [test_gcp_service_identity.output](test_gcp_service_identity.output) <br/>
With or Without proper roles / permission, a plain new gcp service account is able to run above 2 commands to create service identity. This test is against the documentation described in here https://cloud.google.com/sql/docs/postgres/configure-cmek