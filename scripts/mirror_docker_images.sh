#!/bin/bash
MIRROR_NAME='IP_ADDRESS:5000'
KEEP_LOCALIMAGES="${KEEP_LOCALIMAGES:-0}"
declare -a DOCKER_IMAGES=(
docker/compose:1.17.1
docker.elastic.co/elasticsearch/elasticsearch:5.4.1
dockersamples/visualizer
library/mongo:3.4
library/postgres:9.6
registry:2
)

function send_over_ssh()
{
  var img
  var remote_cs
  img="$1"
  remote_cs=user@host
  docker save "${img}" | bzip2 | pv | ssh ${remote_cs} 'bunzip2 | docker load'
}

function process_images()
{
  for image in ${DOCKER_IMAGES[*]}
  do
    docker pull "${image}"
    docker tag "${image}" "${MIRROR_NAME}/${image}"
    docker push "${MIRROR_NAME}/${image}"
    if [ "${KEEP_LOCALIMAGES}" -eq 0 ]; then
      docker rmi "${MIRROR_NAME}/${image}"
      docker rmi "${image}"
    fi
  done
}

process_images
