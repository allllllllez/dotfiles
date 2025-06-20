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

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# ssh-add
# eval `ssh-agent`
# ssh-add ~/.ssh/datum/datum_github

# aws sandbox login
# USAGE: $ aws_login 123456 > .env
function aws_login() {
    local session=`aws sts get-session-token --serial-number arn:aws:iam::921407950230:mfa/m.kajiya --token-code $1 --profile default`
    local AccessKeyId=`echo $session | jq -r '.Credentials.AccessKeyId'`
    local SecretAccessKey=`echo $session | jq -r '.Credentials.SecretAccessKey'`
    local SessionToken=`echo $session | jq -r '.Credentials.SessionToken'`
    echo "export AWS_ACCESS_KEY_ID=$AccessKeyId"
    echo "export AWS_SECRET_ACCESS_KEY=$SecretAccessKey"
    echo "export AWS_SESSION_TOKEN=$SessionToken"
}

function ollama_serve_obsidian() {
    OLLAMA_ORIGINS=app://obsidian.md* ollama serve
}

function ollama_serve() {
    ollama serve
}
