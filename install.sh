#!/bin/bash
set -eu
set -o pipefail

# Little trick, should be rewrited
exesudo() {
    local _funcname_="$1"

    local params=( "$@" )               ## array containing all params passed here
    local tmpfile="/dev/shm/$RANDOM"    ## temporary file
    local filecontent                   ## content of the temporary file
    local regex                         ## regular expression
    local func                          ## function source

    unset params[0]              ## remove first element
    # params=( "${params[@]}" )     ## repack array

    content="#!/bin/bash\n\n"
    content="${content}params=(\n"

    regex="\s+"
    for param in "${params[@]}"
    do
        if [[ "$param" =~ $regex ]]
            then
                content="${content}\t\"${param}\"\n"
            else
                content="${content}\t${param}\n"
        fi
    done

    content="$content)\n"
    echo -e "$content" > "$tmpfile"
    echo "#$( type "$_funcname_" )" >> "$tmpfile"
    echo -e "\n$_funcname_ \"\${params[@]}\"\n" >> "$tmpfile"
    sudo bash "$tmpfile"
    rm "$tmpfile"
}

setup_dotfiles() {
  dotfiles_dir=$1
  local dirname=$(echo $dotfiles_dir | awk -F'/' '{ print $NF }')
  for file in $(find $dotfiles_dir -type f); do
    fn=$(echo $file | awk -F'/' '{print $NF}')
    homedir_file=$HOME${file#$DIRNAME/$dirname}
    mkdir -p ${homedir_file%$fn}
    if [[ -f $homedir_file  ]]; then
      rm -f $homedir_file
    fi
    ln -s $file $homedir_file
  done
}

setup_repos() {
  repo_dir=$1
  for repo in $(ls $repo_dir); do
    echo "Copying $repo to /etc/apt/sources.list.d..."
    cp $repo_dir/$repo /etc/apt/sources.list.d/.
  done
}

install_apt_packages() {
  #set +o pipefail
  apt_pkgs_list=$1

  echo 'Checking if there is an unsigned repos...'
  pubkeys_list=$(apt -qq update 2>&1 | grep 'NO_PUBKEY' | awk '{print $NF}')
  if [[ -n $pubkeys_list ]]; then
    echo "Found $(echo $pubkeys_list | wc -w) unsigned keys, processing..."
    echo $pubkeys_list | xargs -n 1 apt-key adv --keyserver keyserver.ubuntu.com --recv-keys
  fi
  apt update
  FL=()
  for pkg in $(cat $apt_pkgs_list) ; do
    apt install -y $pkg
    if [[ $? -ne 0 ]]; then
      FL+=($pkg)
    fi
  done
  echo 'Failed pakcages list:'
  echo $FL
}

setup_brew() {
  brew_pkgs_list=$1
  brew help || sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
  brew tap burntsushi/ripgrep https://github.com/BurntSushi/ripgrep.git
  for pkg in $(cat $brew_pkgs_list); do
    brew install $pkg
  done
}

setup_ngrok() {
  mkdir -p $HOME/bin
  wget -O /tmp/ngrok.zip https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip
  unzip -o /tmp/ngrok.zip -d $HOME/bin
}

install_pip_packages() {
  pip_pkgs_list=$1
  pip install -U -r $pip_pkgs_list
}

install_gem_packages() {
  gem_pkgs_list=$1
  cat $gem_pkgs_list | xargs -n 1 gem install
}

install_snap_packages() {
  snap_pkgs_list=$1
  cat $snap_pkgs_list | xargs -n 1 -I {} snap install {} --classic
}

install_npm_packages() {
  npm_pkgs_list=$1
  cat $npm_pkgs_list | xargs -n 1 npm install -g
}

clone_bin_from_url () {
  bin_name=$1
  url=$2
  mkdir -p $HOME/bin
  wget -O $HOME/bin/$bin_name $url
  chmod +x $HOME/bin/$bin_name
}

setup_docker_service() {
  cat > /etc/docker/daemon.json << EOF
{
  "bip": "192.168.20.5/24"
}
EOF
 usermod -aG docker $USERNAME
 docker-compose --version || wget -O /usr/local/bin/docker-compose https://github.com/docker/compose/releases/download/1.21.0/docker-compose-$(uname -s)-$(uname -m)
 chmod +x /usr/local/bin/docker-compose
 systemctl restart docker
}

setup_env() {
  export DIRNAME=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)
  export USERNAME=$(whoami)
}

setup_env

while getopts "apgsnbd" opt; do
  case $opt in
    a)
      setup_dotfiles $DIRNAME/dotfiles
      exesudo setup_repos $DIRNAME/pkgs/repos_list
      exesudo install_apt_packages $DIRNAME/pkgs/apt
      exesudo install_snap_packages $DIRNAME/pkgs/snap
      exesudo install_pip_packages $DIRNAME/pkgs/pip
      exesudo install_gem_packages $DIRNAME/pkgs/gem
      exesudo install_npm_packages $DIRNAME/pkgs/npm
      setup_brew $DIRNAME/pkgs/brew
      setup_ngrok
      clone_bin_from_url cerebro https://github.com/KELiON/cerebro/releases/download/v0.3.1/cerebro-0.3.1-x86_64.AppImage
      clone_bin_from_url dockstation https://github.com/DockStation/dockstation/releases/download/v1.4.1/dockstation-1.4.1-x86_64.AppImage
      exesudo setup_docker_service
    ;;
    p)
      exesudo install_pip_packages $DIRNAME/pkgs/pip
    ;;
    g)
      exesudo install_gem_packages $DIRNAME/pkgs/gem
    ;;
    s)
      exesudo install_snap_packages $DIRNAME/pkgs/snap
    ;;
    n)
      exesudo install_npm_packages $DIRNAME/pkgs/npm
    ;;
    b)
      install_brew_packages $DIRNAME/pkgs/brew
    ;;
    d)
      setup_dotfiles $DIRNAME/dotfiles
    ;;
  esac
done

