# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && (eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)")
  alias ls='ls --color=auto'
  #alias dir='dir --color=auto'
  #alias vdir='vdir --color=auto'

  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

alias cat='bat'
alias vim='nvim'
alias vimdiff='nvim -d'
alias check_network='check_host ya.ru'
alias termbin='nc termbin.com 9999'
alias whereami='curl -s ifconfig.co/json | jq'
alias tree='tree --dirsfirst'

eval "$(thefuck --alias)"

alias bd=". bd -si"
alias bd=". bd -si"
#source <(kubectl completion bash)

alias df="df -h | head -n 1; df -h | grep sd |\
    sed -e \"s_/dev/sda[1-9]_\\x1b[34m&\\x1b[0m_\" |\
    sed -e \"s_/dev/sd[b-z][1-9]_\\x1b[33m&\\x1b[0m_\" |\
    sed -e \"s_[,0-9]*[MG]_\\x1b[36m&\\x1b[0m_\" |\
    sed -e \"s_[0-9]*%_\\x1b[32m&\\x1b[0m_\" |\
    sed -e \"s_9[0-9]%_\\x1b[31m&\\x1b[0m_\" |\
    sed -e \"s_/mnt/[-_A-Za-z0-9]*_\\x1b[34;1m&\\x1b[0m_\""

alias copy="xclip -selection c"
alias myip="python -c 'import psutil; import terminaltables; addrs=psutil.net_if_addrs(); table_data=[[\"Interface\", \"Address\"]]; [table_data.append([i, addrs[i][0].address]) for i in addrs]; table = terminaltables.AsciiTable(table_data); print table.table'"

