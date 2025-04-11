#!/bin/bash

# exit on failures
set -e
set -o pipefail

usage() {
  echo "Usage: $(basename "$0") [OPTIONS]" 1>&2
  echo "  -h                - help"
  echo "  -s <source>       - S3 Bucket in the format s3://<ID>"
  echo "  -d <destination>  - Azure Storage Container endpoint"
  echo "  This script copies files to a specified Azure Storage Container."
  echo "  You must specify the following environment variables so that AzCopy "
  echo "  can authenticate with Azure successfully:"
  echo "     - AZCOPY_SPA_APPLICATION_ID : Application ID of a Service Principal in Microsoft Entra"
  echo "     - AZCOPY_SPA_CLIENT_SECRET : Client Secret of a Service Principal in Microsoft Entra"
  echo "     - AZCOPY_TENANT_ID : Tenant ID of your Microsoft Entra directory"
  exit 1
}

while getopts "d:s:h" opt; do
  case $opt in
    s)
      SOURCE=$OPTARG
      ;;
    d)
      DESTINATION=$OPTARG
      ;;
    h)
      usage
      ;;
    *)
      usage
      ;;
  esac
done

if [ -z "$SOURCE" ] || [ -z "$DESTINATION" ]
then
  echo "Error: Source and/or Destination environment variables are not defined!"
  usage
fi

ECS_HOST="169.254.170.2"
AWS_CONTAINER_CREDENTIALS_RELATIVE_URI=$(printenv AWS_CONTAINER_CREDENTIALS_RELATIVE_URI)

if [ -z "$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI" ]
then
  echo "Fatal: Unable to assume role credentials"
  exit 1
fi

CREDENTIALS=$(curl "http://${ECS_HOST}${AWS_CONTAINER_CREDENTIALS_RELATIVE_URI}")

AWS_ACCESS_KEY_ID=$(echo "$CREDENTIALS" | jq -r '.AccessKeyId')
AWS_SECRET_ACCESS_KEY=$(echo "$CREDENTIALS" | jq -r '.SecretAccessKey')
AWS_ROLE_ARN=$(echo "$CREDENTIALS" | jq -r '.RoleArn')
AWS_SESSION_TOKEN=$(echo "$CREDENTIALS" | jq -r '.Token')

echo "Assumed Role: $AWS_ROLE_ARN"
echo "Access Key ID: $AWS_ACCESS_KEY_ID"

if [ -z "$AWS_SECRET_ACCESS_KEY" ]
then
  echo "Fatal: Secret Access Key not set!"
  exit 1
fi

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN

/usr/local/bin/azcopy copy \
  "$SOURCE" \
  "$DESTINATION" \
  --recursive="true" \
  --overwrite="false" \
  --put-md5="true" \
  && echo '==> Done!'
