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
  dotfiles_dir=$1
  dirname=$(echo "$dotfiles_dir" | awk -F'/' '{ print $NF }')
  file_list=$(find "$dotfiles_dir" -type f)
  for file in $file_list; do
    echo "Processing $file..."
    fn=$(echo "$file" | awk -F'/' '{print $NF}')
    homedir_file=$HOME${file#$DIRNAME/$dirname}
    mkdir -p "${homedir_file%$fn}"
    if [[ -f $homedir_file  ]]; then
      rm -f "$homedir_file"
    fi
    ln -s "$file" "$homedir_file"
  done
}

setup_repos() {
  repo_dir=$1
  repo_list=$(ls "$repo_dir")
  for repo in $repo_list; do
    echo "Copying $repo to /etc/apt/sources.list.d..."
    cp "$repo_dir/$repo" /etc/apt/sources.list.d/.
  done
}

install_apt_packages() {
  #set +o pipefail
  apt_pkgs_list=$1

  echo 'Checking if there is an unsigned repos...'
  pubkeys_list=$(apt -qq update 2>&1 | grep 'NO_PUBKEY' | awk '{print $NF}')
  if [[ -n $pubkeys_list ]]; then
    echo "Found $(echo "$pubkeys_list" | wc -w) unsigned keys, processing..."
    echo "$pubkeys_list" | xargs -n 1 apt-key adv --keyserver keyserver.ubuntu.com --recv-keys
  fi
  apt update
  FL=()
  apt_list=$(cat "$apt_pkgs_list")
  for pkg in $apt_list ; do
      if [[ $(dpkg -l "$pkg") ]]; then
      echo "$pkg is already installed, skipping.."
    else
      apt install -y "$pkg"
    fi
    if [[ $? -ne 0 ]]; then
      FL+=($pkg)
    fi
  done
  echo 'Failed pakcages list:'
  echo "${FL[@]}"
}

setup_brew() {
  brew_pkgs_list=$1
  brew help || sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
  brew tap burntsushi/ripgrep https://github.com/BurntSushi/ripgrep.git
  brew_list=$(cat "$brew_pkgs_list")
  for pkg in $brew_list; do
    brew install "$pkg"
  done
}

setup_ngrok() {
  mkdir -p "$HOME/bin"
  wget -O /tmp/ngrok.zip https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip
  unzip -o /tmp/ngrok.zip -d "$HOME/bin"
}

install_pip_packages() {
  pip_pkgs_list=$1
  pip install -U -r "$pip_pkgs_list"
}

install_gem_packages() {
  gem_pkgs_list=$1
  xargs -n 1 gem install < "$gem_pkgs_list"
}

install_snap_packages() {
  snap_pkgs_list=$1
  xargs -n 1 -I {} snap install {} --classic < "$snap_pkgs_list"
}

install_npm_packages() {
  npm_pkgs_list=$1
  xargs -n 1 npm install -g < "$npm_pkgs_list"
}

clone_bin_from_url () {
  bin_name=$1
  url=$2
  mkdir -p "$HOME/bin"
  wget -O "$HOME/bin/$bin_name" "$url"
  chmod +x "$HOME/bin/$bin_name"
}

setup_docker_service() {
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
}

configure_git_repos() {
  git_list=$1
  IFS=$'\n'
  repos_list=$(cat "$git_list")
  for repo in $repos_list; do
    repo_name=$(echo "$repo" | awk '{print $1}')
    path=$(echo "$repo" | awk '{print $2}')
    git clone "$repo_name" "$(eval echo "$path")" 2&>/dev/null || echo "$repo_name already exists in $(eval echo "$path"), skipping..."
  done
}

configure_vim() {
  git clone https://github.com/powerline/fonts.git /tmp/fonts --depth=1
  pushd /tmp/fonts
  ./install.sh
  popd
  vim +PluginInstall +qall
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
while getopts "adgcAPGSNBDh" opt; do
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
  esac
done

