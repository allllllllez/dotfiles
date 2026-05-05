#!/usr/bin/env bash
# set -x

myname=$(basename $0)

# Show Usage
usage() {
    cat << EOS
Description:
    特定ディレクトリ下にあるローカルリポジトリを一気に最新化する

Usage:
    ${myname} <dir_path>

Parameters:
    <dir_path>
        ローカルリポジトリがあるディレクトリ
EOS
}


if [[ -z "$1" ]]; then
    echo -e "Please specify target directory path. \n"
    usage
    exit 1
fi
target_dir=$1

repo_dirs=`find ${target_dir}/* -maxdepth 0 -type d`
for repo_dir in ${repo_dirs};
do
    pushd .
    cd $repo_dir;
    if [[ -e ".git" ]]; then
        echo "pull in $repo_dir"
        git fetch origin
        git pull --ff-only
    fi
    popd
done

