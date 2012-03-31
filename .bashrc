#!/bin/bash

export PGDATA="/usr/local/var/postgres"

# Vi-mode
set -o vi

# Save history whenever command executed
shopt -s histappend # Makes bash append to history rather than overwrite

# Allow to review a history substitution result by loading the resulting line
# into the editing buffer, rather than directly executing it.
shopt -s histverify

# Enable recursive globbing with **
#shopt -s globstar

# Enable extended  pattern matching
shopt -s extglob

source $HOME/.bash/exts/functions.sh

pathmunge $HOME/.bash/bin

source $HOME/.bash/exts/aliases.sh

source $HOME/.bash/exts/prompt.sh

# Gentoo
#export EPREFIX="/usr/local/Gentoo"
#export PATH="$EPREFIX/usr/bin:$EPREFIX/bin:$EPREFIX/tmp/usr/bin:$EPREFIX/tmp/bin:$PATH"
#export CHOST=x86_64-apple-darwin11

# RVM
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
