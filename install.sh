#!/bin/bash
set -xeu
set -o pipefail

# Little trick, should be rewrited
exesudo() {
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# EXESUDO
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
#
# Purpose:
# -------------------------------------------------------------------- #
# Execute a function with sudo
#
# Params:
# -------------------------------------------------------------------- #
# $1:   string: name of the function to be executed with sudo
#
# Usage:
# -------------------------------------------------------------------- #
# exesudo "funcname" followed by any param
#
# -------------------------------------------------------------------- #
# Created 01 September 2012              Last Modified 02 September 2012

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ##
    #
    # LOCAL VARIABLES:
    #
    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ##

    #
    # I use underscores to remember it's been passed
    local _funcname_="$1"

    local params=( "$@" )               ## array containing all params passed here
    local tmpfile="/dev/shm/$RANDOM"    ## temporary file
    local filecontent                   ## content of the temporary file
    local regex                         ## regular expression
    local func                          ## function source


    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ##
    #
    # MAIN CODE:
    #
    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ##

    #
    # WORKING ON PARAMS:
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    #
    # Shift the first param (which is the name of the function)
    unset params[0]              ## remove first element
    # params=( "${params[@]}" )     ## repack array


    #
    # WORKING ON THE TEMPORARY FILE:
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    content="#!/bin/bash\n\n"

    #
    # Write the params array
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

    #
    # Append the function source
    echo "#$( type "$_funcname_" )" >> "$tmpfile"

    #
    # Append the call to the function
    echo -e "\n$_funcname_ \"\${params[@]}\"\n" >> "$tmpfile"


    #
    # DONE: EXECUTE THE TEMPORARY FILE WITH SUDO
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    sudo bash "$tmpfile"
    rm "$tmpfile"
}

#setup_dotfiles() {}

setup_repos() {
  set +x
  repo_dir=$1
  for repo in $(ls $repo_dir); do
    echo "Copying $repo to /etc/apt/sources.list.d..."
    cp $repo_dir/$repo /etc/apt/sources.list.d/.
  done
  set -x
}

install_apt_packages() {
  set +o pipefail
  set +x
  echo 'Checking if there is an unsigned repos...'
  wget -O - http://repo.acestream.org/keys/acestream.public.key | apt-key add -
  pubkeys_list=$(apt -qq update 2>&1 | grep 'NO_PUBKEY' | awk '{print $NF}')
  if [[ -n $pubkeys_list ]]; then
    echo "Found $(echo $pubkeys_list | wc -w) unsigned keys, processing..."
    echo $pubkeys_list | xargs -n 1 apt-key adv --keyserver keyserver.ubuntu.com --recv-keys
  else
    apt update
  fi
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

setup_docker_service() {
  cat > /etc/docker/daemon.json << EOF
{
  "bip": "192.168.20.5/24"
}
EOF
 usermod -aG docker mivanov
 systemctl restart docker
}

#setup_dotfiles
exesudo setup_repos ./repos_list
exesudo install_apt_packages
exesudo install_snap_packages ./snap
exesudo install_pip_packages ./pip
exesudo install_gem_packages ./gem
setup_brew ./linuxbrew
setup_ngrok
exesudo setup_docker_service
