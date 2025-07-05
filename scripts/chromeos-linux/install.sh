#!/usr/bin/env bash
set -x

SCRIPT_DIR="$(cd $(dirname $0); pwd)"
ROOT_DIR=${SCRIPT_DIR}/../..

source ${SCRIPT_DIR}/lib/utils.sh


# 必要なら
sudo apt update
sudo apt upgrade -y

# for neovim
sudo apt install neovim
sudo apt install python3-pip -y

# config files

## bash
BASH_ALIAS_FILE=".bash_aliases"
create bak_and_symlink "${ROOT_DIR}/${BASH_ALIAS_FILE}" "${HOME}/${BASH_ALIAS_FILE}"

## git
GITCONFIG_FILE=".gitconfig"
create bak_and_symlink "${ROOT_DIR}/${GITCONFIG_FILE}" "${HOME}/${GITCONFIG_FILE}"

