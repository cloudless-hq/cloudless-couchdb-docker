#!/usr/bin/env bash

echo "Hello ladies and gentlemen! We're about to do an automated release to Docker Hub."
echo ""

declare -a files=("clouseau/Dockerfile" "couchdb/Dockerfile" "maven-mirror/Dockerfile-mirror" "maven-mirror/Dockerfile-push")

base_path="$(pwd)"
hub_org="cloudlesshq"

echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin

for docker_file in "${files[@]}"
do
  case "$docker_file" in
    clouseau/Dockerfile)
      docker_image="${hub_org}/clouseau"
      docker_version="2.10.0-SNAPSHOT-g$(git rev-parse --short HEAD)"
      build_path="${base_path}/${docker_file}"
      ;;
    couchdb/Dockerfile)
      docker_image="${hub_org}/couchdb"
      docker_version="2.1.1-350f591-g$(git rev-parse --short HEAD)"
      ;;
    maven-mirror/Dockerfile-mirror)
      docker_image="${hub_org}/maven-mirror"
      docker_version=$(git rev-parse --short HEAD)
      ;;
    maven-mirror/Dockerfile-push)
      docker_image="${hub_org}/maven-push"
      docker_version=$(git rev-parse --short HEAD)
      ;;
    *)
      echo "Unknown file: ${docker_file}"
      exit 1
  esac

  build_path="${base_path}/${docker_file}"

  echo ""
  echo "Pushing ${docker_image}:${docker_version} (and :latest)"
  echo "Path: ${build_path}"

  docker build --quiet -t ${docker_image}:latest -t ${docker_image}:${docker_version} -f "${build_path}" . \
    && docker push $docker_image:$docker_version \
    && docker push $docker_image:latest
done

exit 0
