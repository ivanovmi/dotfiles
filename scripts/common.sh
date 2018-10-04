#!/bin/bash

# Logging stuff.
function e_header()   { echo -e "\n\033[1m$@\033[0m"; }
function e_success()  { echo -e " \033[1;32m✔\033[0m  $@"; }
function e_error()    { echo -e " \033[1;31m✖\033[0m  $@"; }
function e_arrow()    { echo -e " \033[1;34m➜\033[0m  $@"; }
function e_dot()      { echo -e " \033[1;34m•\033[0m  $@"; }

function box() { t="$1xxxx";c=${2:--}; b=${3:-|}; echo ${t//?/$c}; echo "$b $1 $b"; echo ${t//?/$c}; }
