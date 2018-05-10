#!/bin/bash
set -eu
set -o pipefail

# Little trick, should be rewrited
exesudo() {
  local _funcname_="$1"
  local params=( "$@" )               ## array containing all params passed here
  local tmpfile="/dev/shm/$RANDOM"    ## temporary file
  local regex                         ## regular expression

  unset params[0]              ## remove first element
  # params=( "${params[@]}" )     ## repack array

  content="#!/bin/bash\n\n"
  content="${content}source "$DIRNAME/scripts/common.sh"\n\n"
  content="${content}params=(\n"

  regex="\s+"
  for param in "${params[@]}"; do
    if [[ "$param" =~ $regex ]]; then
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
  e_header "Stage: setup dotfiles"
  dotfiles_dir=$1
  dirname=$(echo "$dotfiles_dir" | awk -F'/' '{ print $NF }')
  file_list=$(find "$dotfiles_dir" -type f)
  FL=()
  for file in $file_list; do
    fn=$(echo "$file" | awk -F'/' '{print $NF}')
    homedir_file=$HOME${file#$DIRNAME/$dirname}
    mkdir -p "${homedir_file%$fn}"
    if [[ -f $homedir_file  ]]; then
      rm -f "$homedir_file"
    fi
    e_arrow "Linking $fn to ${homedir_file%$fn}..."
    ln -s "$file" "$homedir_file"
    if [[ $? -ne 0 ]]; then
      FL+=($file)
    fi
  done
  if [[ ${#FL[@]} -eq 0 ]]; then
    e_success "All files successfully linked!"
  else
    e_error "Failed to link $(IFS=" "; echo ${FL[*]})"
  fi
}

setup_repos() {
  e_header "Stage: copying repos"
  repo_dir=$1
  repo_list=$(ls "$repo_dir")
  FL=()
  for repo in $repo_list; do
    e_arrow "Copying $repo to /etc/apt/sources.list.d..."
    cp "$repo_dir/$repo" /etc/apt/sources.list.d/.
    if [[ $? -ne 0 ]]; then
      FL+=($repo)
    fi
  done
  if [[ ${#FL[@]} -eq 0 ]]; then
    e_success "Repos successfully copied!"
  else
    e_error "Failed to copy repos $(IFS=" "; echo ${FL[*]})"
  fi
}

install_apt_packages() {
  set +o pipefail
  apt_pkgs_list=$1
  e_header "Stage: installing apt pkgs"
  e_arrow 'Checking if there is an unsigned repos...'
  pubkeys_list=$(apt -qq update 2>&1 | grep 'NO_PUBKEY' | awk '{print $NF}')
  if [[ -n $pubkeys_list ]]; then
    e_dot "Found $(echo "$pubkeys_list" | wc -w) unsigned keys, processing..."
    echo "$pubkeys_list" | xargs -n 1 apt-key adv --keyserver keyserver.ubuntu.com --recv-keys
  else
    e_dot "Unsigned repos not found"
  fi
  apt update
  FL=()
  apt_list=$(cat "$apt_pkgs_list")
  for pkg in $apt_list ; do
      if [[ $(dpkg -l "$pkg") ]]; then
      e_arrow "$pkg is already installed, skipping.."
    else
      apt install -y "$pkg"
    fi
    if [[ $? -ne 0 ]]; then
      FL+=($pkg)
    fi
  done
  if [[ ${#FL[@]} -eq 0 ]]; then
    e_success "Packages successfully installed!"
  else
    e_error "Failed to install pkgs $(IFS=" "; echo ${FL[*]})"
  fi
}

setup_brew() {
  e_header "Stage: installing brew pkgs"
  brew_pkgs_list=$1
  e_arrow "Checking if brew installed"
  brew help || (e_dot "Brew bin not found, installing"; sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)")
  brew tap burntsushi/ripgrep https://github.com/BurntSushi/ripgrep.git
  brew_list=$(cat "$brew_pkgs_list")
  FL=()
  for pkg in $brew_list; do
    brew install "$pkg"
    if [[ $? -ne 0 ]]; then
      FL+=($pkg)
    fi
  done
  if [[ ${#FL[@]} -eq 0 ]]; then
    e_success "Packages successfully installed!"
  else
    e_error "Failed to install pkgs $(IFS=" "; echo ${FL[*]})"
  fi
}

setup_ngrok() {
  mkdir -p "$HOME/bin"
  wget -O /tmp/ngrok.zip https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip
  unzip -o /tmp/ngrok.zip -d "$HOME/bin"
}

install_pip_packages() {
  e_header "Stage: installing pip packages"
  pip_pkgs_list=$1
  pip install -U -r "$pip_pkgs_list"
  if [[ $? -ne 0 ]]; then
    e_error "Failed to install pip pkgs"
  else
    e_success "pip pkgs successfully installed"
  fi
}

install_gem_packages() {
  e_header "Stage: installing gem packages"
  gem_pkgs_list=$1
  xargs -n 1 gem install < "$gem_pkgs_list"
  if [[ $? -ne 0 ]]; then
    e_error "Failed to install gem pkgs"
  else
    e_success "gem pkgs successfully installed"
  fi
}

install_snap_packages() {
  e_header "Stage: installing snap packages"
  snap_pkgs_list=$1
  xargs -n 1 -I {} snap install {} --classic < "$snap_pkgs_list"
  if [[ $? -ne 0 ]]; then
    e_error "Failed to install snap pkgs"
  else
    e_success "snap pkgs successfully installed"
  fi
}

install_npm_packages() {
  e_header "Stage: installing npm packages"
  npm_pkgs_list=$1
  xargs -n 1 npm install -g < "$npm_pkgs_list"
  if [[ $? -ne 0 ]]; then
    e_error "Failed to install npm pkgs"
  else
    e_success "npm pkgs successfully installed"
  fi
}

clone_bin_from_url () {
  e_header "Stage: download bin $1"
  bin_name=$1
  url=$2
  mkdir -p "$HOME/bin"
  e_arrow "Clonning $bin_name to $HOME/bin directory..."
  FL=()
  if ! (wget -O "$HOME/bin/$bin_name" "$url"); then
    FL+=(1)
  fi
  if ! (chmod +x "$HOME/bin/$bin_name"); then
    FL+=(2)
  fi
  if [[ ${#FL[@]} -eq 0 ]]; then
    e_success "Successfully downloaded $bin_name"
  else
    e_error "Failed to download $bin_name"
  fi
}

setup_docker_service() {
  e_header "Stage: setup docker"
  cat > /etc/docker/daemon.json << EOF
{
  "bip": "192.168.20.5/24"
}
EOF
 usermod -aG docker "$USERNAME"
 docker-compose --version || wget -O /usr/local/bin/docker-compose "https://github.com/docker/compose/releases/download/1.21.0/docker-compose-$(uname -s)-$(uname -m)"
 chmod +x /usr/local/bin/docker-compose
 systemctl restart docker
}

setup_env() {
  DIRNAME=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  USERNAME=$(whoami)
  export DIRNAME
  export USERNAME
  source "$DIRNAME/scripts/common.sh"
}

configure_git_repos() {
  e_header "Stage: clone git repos"
  git_list=$1
  IFS=$'\n'
  repos_list=$(cat "$git_list")
  for repo in $repos_list; do
    repo_name=$(echo "$repo" | awk '{print $1}')
    path=$(echo "$repo" | awk '{print $2}')
    e_arrow "Clonning $repo_name"
    git clone "$repo_name" "$(eval echo "$path")" 2&>/dev/null || e_dot "$repo_name already exists in $(eval echo "$path"), skipping..."
  done
}

configure_vim() {
  e_header "Stage: configuring vim"
  e_arrow "Clonning patched fonts"
  git clone https://github.com/powerline/fonts.git /tmp/fonts --depth=1 || e_dot "fonts already clonned, skipping"
  pushd /tmp/fonts
  ./install.sh
  popd
  e_arrow "Install vim plugins"
  vim +PluginInstall +qall
}

setup_go() {
  wget -O /tmp/golang_installer https://storage.googleapis.com/golang/getgo/installer_linux
  chmod +x /tmp/golang_installer
  /tmp/golang_installer
}

print_help() {
  echo '-h - print this help'
  echo '-a - bootstrap all'
  echo '-d - bootstrap docker'
  echo '-g - bootstrap git repos'
  echo '-c - configure vim'
  echo '-A - install apt packages'
  echo '-P - install pip packages'
  echo '-G - install gem packages'
  echo '-S - install snap packages'
  echo '-N - install npm packages'
  echo '-B - install brew packages'
  echo '-D - install dotfiles'
}

setup_env
while getopts "adgcAPGSNBDho" opt; do
  case $opt in
    a)
      setup_dotfiles "$DIRNAME"/dotfiles
      exesudo setup_repos "$DIRNAME"/pkgs/repos_list
      exesudo install_apt_packages "$DIRNAME"/pkgs/apt
      exesudo install_snap_packages "$DIRNAME"/pkgs/snap
      exesudo install_pip_packages "$DIRNAME"/pkgs/pip
      exesudo install_gem_packages "$DIRNAME"/pkgs/gem
      exesudo install_npm_packages "$DIRNAME"/pkgs/npm
      configure_git_repos "$DIRNAME"/pkgs/git
      setup_brew "$DIRNAME"/pkgs/brew
      setup_ngrok
      clone_bin_from_url cerebro https://github.com/KELiON/cerebro/releases/download/v0.3.1/cerebro-0.3.1-x86_64.AppImage
      clone_bin_from_url dockstation https://github.com/DockStation/dockstation/releases/download/v1.4.1/dockstation-1.4.1-x86_64.AppImage
      clone_bin_from_url tmuxinator.bash https://raw.githubusercontent.com/tmuxinator/tmuxinator/master/completion/tmuxinator.bash
      exesudo setup_docker_service
      configure_vim
    ;;
    d)
      exesudo setup_docker_service
    ;;
    A)
      exesudo setup_repos "$DIRNAME/pkgs/repos_list"
      exesudo install_apt_packages "$DIRNAME/pkgs/apt"
    ;;
    P)
      exesudo install_pip_packages "$DIRNAME"/pkgs/pip
    ;;
    G)
      exesudo install_gem_packages "$DIRNAME"/pkgs/gem
    ;;
    S)
      exesudo install_snap_packages "$DIRNAME"/pkgs/snap
    ;;
    N)
      exesudo install_npm_packages "$DIRNAME"/pkgs/npm
    ;;
    B)
      setup_brew "$DIRNAME"/pkgs/brew
    ;;
    D)
      clone_bin_from_url tmuxinator.bash https://raw.githubusercontent.com/tmuxinator/tmuxinator/master/completion/tmuxinator.bash
      setup_dotfiles "$DIRNAME"/dotfiles
    ;;
    g)
      configure_git_repos "$DIRNAME"/pkgs/git
    ;;
    c)
      configure_vim
    ;;
    h)
      print_help
    ;;
    o)
      setup_go
    ;;
  esac
done

