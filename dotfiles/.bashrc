# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples
# We use preexec and precmd hook functions for Bash
# If you have anything that's using the Debug Trap or PROMPT_COMMAND
# change it to use preexec or precmd
# See also https://github.com/rcaloras/bash-preexec

# If not running interactively, don't do anything
case $- in
  *i*) ;;
  *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=32768
HISTFILESIZE=32768

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
  xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
  if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    # We have color support; assume it's compliant with Ecma-48
    # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
    # a case would tend to support setf rather than setaf.)
    color_prompt=yes
  else
    color_prompt=
  fi
fi

if [ "$color_prompt" = yes ]; then
  PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
  PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
fi

if [ -f ~/.bash_functions ]; then
  . ~/.bash_functions
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# If this is an xterm set more declarative titles
# "dir: last_cmd" and "actual_cmd" during execution
# If you want to exclude a cmd from being printed see line 156
case "$TERM" in
xterm*|rxvt*|terminator)
  PS1="\\[\\e]0;${debian_chroot:+($debian_chroot)}\$(print_title)\\a\\]$PS1"
  __el_LAST_EXECUTED_COMMAND=""
  print_title ()
  {
    __el_FIRSTPART=""
    __el_SECONDPART=""
    if [ "$PWD" == "$HOME" ]; then
      __el_FIRSTPART=$(gettext --domain="pantheon-files" "Home")
    else
      if [ "$PWD" == "/" ]; then
        __el_FIRSTPART="/"
      else
        __el_FIRSTPART="${PWD##*/}"
      fi
    fi
    if [[ "$__el_LAST_EXECUTED_COMMAND" == "" ]]; then
      echo "$__el_FIRSTPART"
      return
    fi
    #trim the command to the first segment and strip sudo
    if [[ "$__el_LAST_EXECUTED_COMMAND" == sudo* ]]; then
      __el_SECONDPART="${__el_LAST_EXECUTED_COMMAND:5}"
      __el_SECONDPART="${__el_SECONDPART%% *}"
    else
      __el_SECONDPART="${__el_LAST_EXECUTED_COMMAND%% *}"
    fi
    printf "%s: %s" "$__el_FIRSTPART" "$__el_SECONDPART"
  }
  put_title()
  {
    __el_LAST_EXECUTED_COMMAND="${BASH_COMMAND}"
    printf "\\033]0;%s\\007" "$1"
  }

  # Show the currently running command in the terminal title:
  # http://www.davidpashley.com/articles/xterm-titles-with-bash.html
  update_tab_command()
  {
    # catch blacklisted commands and nested escapes
    case "$BASH_COMMAND" in
      *\\033]0*|update_*|echo*|printf*|clear*|cd*)
      __el_LAST_EXECUTED_COMMAND=""
      ;;
      *)
      put_title "${BASH_COMMAND}"
      ;;
    esac
  }
  preexec_functions+=(update_tab_command)
  ;;
*)
;;
esac



if [[ $TERM == xterm ]]; then
  TERM=xterm-256color
fi

# add this configuration to ~/.bashrc
export HH_CONFIG=hicolor         # get more colors
shopt -s histappend              # append new history items to .bash_history
export HISTCONTROL=ignoreboth    #
export HISTFILESIZE=32768        # increase history file size (default is 500)
export HISTSIZE=${HISTFILESIZE}  # increase history size (default is 500)
export HISTIGNORE="ls:ls *:cd:cd -:pwd:exit:date:* --help:glances:fg:bg:history"
export PROMPT_COMMAND="history -a; history -n; ${PROMPT_COMMAND}"   # mem/file sync

if [ -f ~/.bash_exports ]; then
  . ~/.bash_exports
fi

complete -C /home/mivanov/go/bin/gocomplete go

# Deepin broke kb layout switch, so
# setxkbmap -model pc105 -layout us,ru -option grp:alt_shift_toggle

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
