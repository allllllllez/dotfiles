#!/usr/bin/env bash
set -x

SCRIPT_DIR="$(cd $(dirname $0); pwd)"
ROOT_DIR=${SCRIPT_DIR}/..

source ${SCRIPT_DIR}/lib/utils.sh

# install
## neovim config
NEOVIM_CONFIG_FILE=".config"
create bak_and_symlink "${ROOT_DIR}/${NEOVIM_CONFIG_FILE}" "${HOME}/${NEOVIM_CONFIG_FILE}"

