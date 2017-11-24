#!/bin/bash
# Set to fail script if any command fails.
set -e

echo "################################################################################"

if [ $# -ne 1 ]; then
  echo "Usage: $0 [SampleService-dev|SampleService]"
  exit 1
fi
EB_ENV_NAME=$1

echo "DEPLOY_STEP: Check environment variables required by the Dockerfile"
[[ -z "$PIP_INDEX_URL" ]] && echo "DEPLOY_STEP: PIP_INDEX_URL env variable is required. Exit now." && exit 1
[[ -z "$AWS_ACCESS_KEY_ID" ]] && echo "DEPLOY_STEP: AWS_ACCESS_KEY_ID env variable is required. Exit now." && exit 1
[[ -z "$AWS_SECRET_ACCESS_KEY" ]] && echo "DEPLOY_STEP: AWS_SECRET_ACCESS_KEY env variable is required. Exit now." && exit 1

echo "DEPLOY_STEP: Create virtual env for EB deployment"
rm -rf env_deploy
virtualenv -p python3 env_deploy
. env_deploy/bin/activate

echo "DEPLOY_STEP: Install dependencies"
python -m pip install -r requirements-deploy.txt

pushd ../app

echo "DEPLOY_STEP: Update Dockerfile with environment variable before calling EB"
cp Dockerfile Dockerfile.orig
cat Dockerfile.orig | envsubst > Dockerfile

echo "DEPLOY_STEP: Deploy EB environment ${EB_ENV_NAME}"
time eb deploy $EB_ENV_NAME | tee /dev/stderr | grep "update completed successfully"

# Revert the changes to Dockerfile
mv Dockerfile.orig Dockerfile

popd

# Leave virtual environment
deactivate
