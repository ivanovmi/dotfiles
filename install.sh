#!/bin/bash
set -xeu
set -o pipefail

setup_repos() {
  set +x
  repo_dir=$1
  for repo in $(ls $repo_dir); do
    echo "Copying $repo to /etc/apt/sources.list.d..."
    cp $repo_dir/$repo /etc/apt/sources.list.d/.
  done
  set -x
}

install_packages() {
  set +o pipefail
  set +x
  echo 'Checking if there is an unsigned repos...'
  pubkeys_list=$(apt -qq update 2>&1 | grep 'NO_PUBKEY' | awk '{print $NF}')
  if [[ -n $pubkeys_list ]]; then
    echo "Found $(echo $pubkeys_list | wc -w) unsigned keys, processing..."
    echo $pubkeys_list | xargs -n 1 apt-key adv --keyserver keyserver.ubuntu.com --recv-keys
  else
    apt update
  fi
}

#install_pip_packages() {}

#install_gem_packages() {}

setup_repos ./repos_list
install_packages
#install_pip_packages
#install_gem_packages
