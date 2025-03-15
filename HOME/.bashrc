#!/usr/bin/bash

########################################
#
# PATH
#
########################################

# aws cli
export PATH=/c/Program\ Files/Amazon/AWSCLIV2/:${PATH}

# npm
export PATH=${HOME}/AppData/Local/nvm:${PATH}

########################################
#
# Alias
#
########################################

# 「the input device is not a TTY..」対策で winpty をつける
alias docker='winpty docker'

alias nv='nvim'
alias la='ls -la'

# [ -f ~/.fzf.bash ] && source ~/.fzf.bash
