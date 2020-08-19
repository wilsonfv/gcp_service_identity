#!/bin/bash

echo '========== Display gcloud version =========='
gcloud version

echo '========== Display gcloud config =========='
gcloud config list

export GCP_PROJECT_ID=$(gcloud config list --format='value(core.project)')
export GCP_USER_ACCOUNT=$(gcloud config list --format='value(core.account)')

echo '========== Display IAM roles assigned to gcp user account =========='
gcloud projects get-iam-policy ${GCP_PROJECT_ID} \
    --flatten='bindings[].members[]' \
    --format='table(bindings.role,bindings.members)' \
    | grep ${GCP_USER_ACCOUNT}

export APIS_NEEDED='cloudkms.googleapis.com'
if [[ ! $(gcloud services list --enabled \
            --project ${GCP_PROJECT_ID} \
            --format='csv[no-heading](NAME)' \
            --filter="NAME=${APIS_NEEDED}") ]]; then
    gcloud services enable ${APIS_NEEDED} --project ${GCP_PROJECT_ID} -q
fi
export APIS_NEEDED='serviceusage.googleapis.com'
if [[ ! $(gcloud services list --enabled \
            --project ${GCP_PROJECT_ID} \
            --format='csv[no-heading](NAME)' \
            --filter="NAME=${APIS_NEEDED}") ]]; then
    gcloud services enable ${APIS_NEEDED} --project ${GCP_PROJECT_ID} -q
fi

echo '========== Display enabled APIs =========='
gcloud services list --enabled --project ${GCP_PROJECT_ID}

echo '========== Create a gcp service account =========='
export GCP_SERVICE_ACCOUNT_SHORT_NAME="sa-test"
export GCP_SERVICE_ACCOUNT_NAME="${GCP_SERVICE_ACCOUNT_SHORT_NAME}-$RANDOM"
gcloud iam service-accounts create ${GCP_SERVICE_ACCOUNT_NAME} \
    --description="service account to test service identity" \
    --display-name=${GCP_SERVICE_ACCOUNT_NAME} \
    --project ${GCP_PROJECT_ID}
export GCP_SERVICE_ACCOUNT=$(gcloud iam service-accounts list \
                                --format='csv[no-heading](EMAIL)' \
                                --filter="NAME=${GCP_SERVICE_ACCOUNT_NAME}" \
                                --project ${GCP_PROJECT_ID})
echo "========== gcp service account: ${GCP_SERVICE_ACCOUNT} =========="

echo '========== Generate key for gcp service account =========='
gcloud iam service-accounts keys create ${GCP_SERVICE_ACCOUNT_NAME}.json \
    --iam-account ${GCP_SERVICE_ACCOUNT} \
    --project ${GCP_PROJECT_ID}

echo '========== Authenticate gcp service account =========='
gcloud auth activate-service-account --key-file ${GCP_SERVICE_ACCOUNT_NAME}.json
gcloud config list

# https://cloud.google.com/sql/docs/postgres/configure-cmek
echo '========== Use gcp service account to create service identity service account in which previously is not possible =========='
gcloud beta services identity create --service=sqladmin.googleapis.com \
    --project=${GCP_PROJECT_ID}
gcloud beta services identity create --service=servicenetworking.googleapis.com \
    --project=${GCP_PROJECT_ID}

echo '========== Switch back to gcp user account =========='
gcloud config set account ${GCP_USER_ACCOUNT}
gcloud config list

echo '========== Grant role to gcp service account =========='
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} \
    --member=serviceAccount:${GCP_SERVICE_ACCOUNT} \
    --role=roles/cloudsql.admin -q >/dev/null
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} \
    --member=serviceAccount:${GCP_SERVICE_ACCOUNT} \
    --role=roles/iam.securityAdmin -q >/dev/null

echo '========== Display IAM roles assigned to gcp service account =========='
gcloud projects get-iam-policy ${GCP_PROJECT_ID} \
    --flatten='bindings[].members[]' \
    --format='table(bindings.role,bindings.members)' \
    | grep "${GCP_SERVICE_ACCOUNT}"

echo '========== Generate key for gcp service account =========='
gcloud iam service-accounts keys create ${GCP_SERVICE_ACCOUNT_NAME}.json \
    --iam-account ${GCP_SERVICE_ACCOUNT} \
    --project ${GCP_PROJECT_ID}

echo '========== Authenticate gcp service account =========='
gcloud auth activate-service-account --key-file ${GCP_SERVICE_ACCOUNT_NAME}.json
gcloud config list

# https://cloud.google.com/sql/docs/postgres/configure-cmek
echo '========== Use gcp service account to create service identity service account in which previously is not possible =========='
gcloud beta services identity create --service=sqladmin.googleapis.com \
    --project=${GCP_PROJECT_ID}
gcloud beta services identity create --service=servicenetworking.googleapis.com \
    --project=${GCP_PROJECT_ID}

echo '========== Clean up =========='
gcloud config set account ${GCP_USER_ACCOUNT}

if [[ -f ${GCP_SERVICE_ACCOUNT_NAME}.json ]]; then
    rm -f ${GCP_SERVICE_ACCOUNT_NAME}.json
fi

for sa in $(gcloud iam service-accounts list \
            --format='csv[no-heading](EMAIL)' \
            --filter="NAME:${GCP_SERVICE_ACCOUNT_SHORT_NAME}*" \
            --project ${GCP_PROJECT_ID})
do
    gcloud iam service-accounts delete ${sa} --project ${GCP_PROJECT_ID} -q
done
