#!/bin/sh

VPS_DIR="/root/vps"
MASTER="ssh://git@freyr.erifax.org:35/home/git/vps.git"

export GIT_SSH="$(pwd)/bootstrap/git-ssh.sh"
git clone ${MASTER} ${VPS_DIR}
