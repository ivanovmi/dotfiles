function weather {
  city=${1:-Saratov};
  curl -4 "http://wttr.in/$city"
}

function check_host {
  host=${1}
  count=1
  while true ; do
    if ping -c 1 -w 2 "$host" > /dev/null 2>&1; then
      alert;
      echo "Host $host is accessible after $count retries...";
      break;
    else
      echo "Host $host is unaccessible for now after $count retries, sleeping 5..."
      sleep 5
    fi
    (( count+=1 ))
  done
}

function parse_git_branch {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

function show_time {
  echo "${COLOR_GRAY}$(date +%H:%M)${COLOR_NONE}"
}

function get_time {
  while sleep 1 ; do
    tput sc
    tput cup 0 $(($(tput cols)-11))
    echo -e "\e[31m`date +%r`\e[39m"
    tput rc
  done &
}

function mkdircd {
  mkdir -p "$@" && eval cd "\"\$$#\"";
}

