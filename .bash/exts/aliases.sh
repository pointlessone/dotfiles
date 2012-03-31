alias l='ls -lAh'
alias la='ls -lA'
alias ..='cd ..'
alias cd..='cd ..'

# OS X Quick Look from terminal
alias ql='qlmanage -p'

alias scpresume="rsync --partial --progress --rsh=ssh"

# VimPager
export PAGER=$HOME/.bash/bin/vimpager
alias less=$PAGER
alias zless=$PAGER
