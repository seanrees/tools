#!/bin/sh

export GIT_SSH="/root/vps/bootstrap/git-ssh.sh"

# Return an error if not up-to-date. This way we stop the reconfig.
cd /root/vps && (/usr/local/bin/git pull | grep up-to-date) 2>&1 >/dev/null

if [ $? -eq 0 ]; then
  exit 1
else
  exit 0
fi
