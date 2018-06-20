#!/usr/bin/env bash

echo "Hello ladies and gentlemen! We're about to do an automated release to Docker Hub."
echo ""

declare -a files=("clouseau/Dockerfile" "couchdb/Dockerfile")

base_path="$(pwd)"
hub_org="cloudlesshq"

echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin

for docker_file in "${files[@]}"
do
  case "$docker_file" in
    clouseau/Dockerfile)
      docker_image="${hub_org}/test-clouseau"
      docker_version="2.10.0-SNAPSHOT-g$(git rev-parse --short HEAD)"
      build_path="${base_path}/clouseau"
      ;;
    couchdb/Dockerfile)
      docker_image="${hub_org}/test-couchdb"
      docker_version="2.1.1-350f591-g$(git rev-parse --short HEAD)"
      build_path="${base_path}/couchdb"
      ;;
    *)
      echo "Unknown file: ${docker_file}"
      exit 1
  esac

  echo ""
  echo "Pushing ${docker_image}:${docker_version} (and :latest)"
  echo "Path: ${build_path}"

  docker build -t ${docker_image}:latest -t ${docker_image}:${docker_version} -f "${build_path}/Dockerfile" . \
    && docker push $docker_image:$docker_version \
    && docker push $docker_image:latest
done

exit 0
