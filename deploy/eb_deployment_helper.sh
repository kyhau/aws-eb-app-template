#!/bin/bash

# Set to fail script if any command fails.
set -e

# Define constants
SCRIPT_DIR=$(dirname $(realpath $0))
APP_DIR=$(dirname ${SCRIPT_DIR})/app
PYTHON_VERSION=python3.6
APP_NAME=sample_service
DOCKER_REPO="khau/${APP_NAME}"


# Cleanup hack at the end
function finish {
  [[ -f ${APP_DIR}/DockerfileWithEnvVars ]] && rm ${APP_DIR}/DockerfileWithEnvVars
  [[ -f ${APP_DIR}/Dockerfile.orig ]] && mv ${APP_DIR}/Dockerfile.orig ${APP_DIR}/Dockerfile
  cd ${SCRIPT_DIR}
  echo "goodbye"
}
trap finish EXIT

# Define the help menu
help_menu() {
  echo "Usage:
  ${0##*/}
    --build-image                Build/test docker image with CONFIG_FILE.
    --eb-config-update           Run eb command to update EB environment of EB_ENV_NAME (on After Creation).
    --eb-deploy                  Deploy the application using Dockerfile.
    --eb-env EB_ENV_NAME         EB environment: [SampleService-dev|SampleService-staging|SampleService]
    --push-image                 Push a copy of the Docker image (from --build-image) to Docker registry for backup.
  "
  exit
}

# Parse arguments
DO_DOCKER_BUILD=false
DO_DOCKER_PUSH=false
DO_EB_DEPLOY=false
DO_EB_CONFIG_UPDATE=false
while [[ "$#" > 0 ]]; do case $1 in
    --build-image)       DO_DOCKER_BUILD=true                     ;;
    --push-image)        DO_DOCKER_PUSH=true                      ;;
    --eb-config-update)  DO_EB_CONFIG_UPDATE=true                 ;;
    --eb-deploy)         DO_EB_DEPLOY=true                        ;;
    --eb-env)            EB_ENV_NAME="${2}"               ; shift ;;
    -h|--help)           help_menu                                ;;
    *)                   echo "Invalid option: ${1}" && help_menu ;;
esac; shift; done

function missed_var_error {
  [[ ! -z "$3" ]] || (echo "CHECK_POINT: $1 $2 is not provided. Exit now." && exit 1)
}

# Check arguments and environment variables
if [[ "$DO_DOCKER_BUILD" = true ]] ||  [[ "DO_EB_DEPLOY" = true ]] ; then
  missed_var_error "Env-variable" "PIP_INDEX_URL" ${PIP_INDEX_URL}

  # Prepare the Dockerfile
  cd ${APP_DIR}
  cp Dockerfile Dockerfile.orig
  cat Dockerfile | envsubst > DockerfileWithEnvVars
fi
if [[ "$DO_EB_DEPLOY" = true ]] || [[ "$DO_EB_CONFIG_UPDATE" = true ]] ; then
  missed_var_error "Argument" "EB_ENV_NAME" ${EB_ENV_NAME}

  cd ${SCRIPT_DIR}
  virtualenv -p ${PYTHON_VERSION} env_eb_update
  . env_eb_update/bin/activate
  python -m pip install -r requirements-deploy.txt
  deactivate    # env_eb_update
fi


####################################################################################################

if [[ "$DO_DOCKER_BUILD" = true ]] ; then
  echo "################################################################################"
  echo "CHECK_POINT: Started building docker image for testing"

  cd ${APP_DIR}
  virtualenv -p ${PYTHON_VERSION} env_container
  . env_container/bin/activate
  python -m pip install -e .

  # Extract info from repo and initialise the image version tag names
  version=`python -c "import pkg_resources; print(pkg_resources.get_distribution('${APP_NAME}').version)"`
  version_tag=${DOCKER_REPO}:$version

  echo "CHECK_POINT: Build docker image: ${version_tag}"
  docker build -t $version_tag -f DockerfileWithEnvVars .

  echo "CHECK_POINT: Start the image tests using a container"
  # Just call pserve to see if it is ready, without passing the actual config file.
  docker run --rm "${version_tag}" pserve | grep "You must give a config file"
  [[ $? -eq 0 ]] || (echo "CHECK_POINT: Docker image test failed. Exit now." && exit 1)
  echo "CHECK_POINT: Docker image test passed."

  if [[ "$DO_DOCKER_PUSH" = true ]] ; then
    echo "CHECK_POINT: Push to docker registry"
    docker tag $version_tag ${DOCKER_REPO}:latest

    docker push ${version_tag} || echo "Failure: ${version_tag} push failed."
    docker push $latest_tag || echo "Failure: ${latest_tag} push failed."

    # Cleanup builder image list
    echo "CHECK_POINT: Cleanup versions"
    docker rmi $version_tag $latest_tag
  fi

  deactivate    # env_container
fi


####################################################################################################

if [[ "$DO_EB_CONFIG_UPDATE" = true ]] ; then
  echo "################################################################################"
  echo "CHECK_POINT: Started running eb config update - this may recreate some AWS resources"

  . ${SCRIPT_DIR}/env_eb_update/bin/activate
  cd ${APP_DIR}

  # Use build_log_parser.txt to parse the console and fail the build
  # Note: Do `eb config save` again and compare the file first
  eb use ${EB_ENV_NAME}
  eb config --cfg ${EB_ENV_NAME}

  deactivate    # env_eb_update
fi

####################################################################################################

if [[ "$DO_EB_DEPLOY" = true ]] ; then
  echo "################################################################################"
  echo "CHECK_POINT: Started running eb deploy - this will deploy application and update any settings within the EC2s"

  . ${SCRIPT_DIR}/env_eb_update/bin/activate
  cd ${APP_DIR}

  echo "REVISION = '`git rev-parse HEAD`'" > sample_service/__revision__.py
  mv DockerfileWithEnvVars Dockerfile

  # Use build_log_parser.txt to parse the console and fail the build
  time eb deploy $EB_ENV_NAME

  deactivate    # env_eb_update
fi
