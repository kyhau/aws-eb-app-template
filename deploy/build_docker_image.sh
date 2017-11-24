#!/bin/bash

# Cleanup hack at the end
function finish {
  rm DockerfileWithEnvVars || echo "goodbye"
  popd
}
trap finish EXIT

pushd ../app

# #############################################################################
# Make sure we have the environment variables required by Dockerfile exported
# #############################################################################
[[ -z "$PIP_INDEX_URL" ]] && echo "DOCKER_BUILD: PIP_INDEX_URL env variable is required. Exit now." && exit 1

echo "DOCKER_BUILD: Create virtual env for building container"
set -e
rm -rf env_container
virtualenv -p python3 env_container
. env_container/bin/activate
echo "DOCKER_BUILD: Install application with pip"
pip install -e .

# #############################################################################
# Extract info from repo
# #############################################################################
version=`python -c "import pkg_resources; print(pkg_resources.get_distribution('sample_service').version)"`
repo="docker.example.com/services/sample_service"

# #############################################################################
# Parse arguments
# #############################################################################
# Optional pushing to registry
push=false

# use only major / minor version, ignore bugfixes
short_version=`echo $version | sed -r 's/([0-9]+\.[0-9]+)\.[0-9]+/\1/'`

while [[ $# > 0 ]] ; do
  key="$1"
  case $key in
    -p|--push)
      push=true
      ;;
    *)
      echo "Unknown arg: $1"
      ;;
  esac
  shift
done

# #############################################################################
# Initialise version tag names
# #############################################################################
# Version numbers
version_tag=$repo:$version
short_version_tag=$repo:$short_version
latest_tag=$repo:latest
echo "DOCKER_BUILD: Versions for images"
echo $version_tag
echo $short_version_tag
echo $latest_tag

# Convoluted way to call docker build and pass the env variable
# https://stackoverflow.com/questions/19537645/get-environment-variable-value-in-dockerfile
echo  "DOCKER_BUILD: Build docker image"
cat Dockerfile | envsubst > DockerfileWithEnvVars
docker build -t $version_tag -f DockerfileWithEnvVars .

# #############################################################################
# TODO Start the image tests using a container
# #############################################################################
# E.g. for pyramid: Just call pserve to see if it is ready, without passing the actual config file.
#echo  "DOCKER_BUILD: Run image test"
#docker run --rm "${version_tag}" pserve | grep "You must give a config file"
#[[ $? -eq 0 ]] || (echo "DOCKER_BUILD: Docker image test failed. Exit now." && exit 1)
#echo "DOCKER_BUILD: Docker image test passed."

if [ "$push" = true ] ; then
  docker tag $version_tag $short_version_tag
  docker tag $version_tag $latest_tag
  # Push to registry
  echo "DOCKER_BUILD: Push to docker registry"
  ( docker push ${version_tag} && send_email "${version_tag}" )|| echo "Failure: ${version_tag} push failed."
  docker push $latest_tag
  docker push $short_version_tag
  # Cleanup builder image list
  echo "DOCKER_BUILD: Cleanup versions"
  docker rmi $latest_tag
  docker rmi $short_version_tag
fi

# Leave virtual environment env_container
deactivate
