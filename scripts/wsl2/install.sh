#!/usr/bin/env bash
set -x

SCRIPT_DIR="$(cd $(dirname $0); pwd)"
ROOT_DIR=${SCRIPT_DIR}/../../wsl2

source ${SCRIPT_DIR}/lib/utils.sh

# install
## neovim
sudo apt install -y ninja-build gettext gcc cmake unzip curl

NEOVIM_DIR=${HOME}/neovim
git clone https://github.com/neovim/neovim.git ${NEOVIM_DIR}
cd ${NEOVIM_DIR}

make CMAKE_BUILD_TYPE=Release
sudo make install
cat << 'EOF' >> ~/.bashrc
export PATH="$(pwd)/build/bin/nvim:$PATH"
EOF

