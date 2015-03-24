#!/bin/sh

ADMIN=srees
UID=1001
GID=20

pw user show ${ADMIN} >/dev/null 2>&1
if [ ! $? -eq 0 ]; then
  echo "Creating user ${ADMIN}"
  pw user add -n ${ADMIN} -c "Sean Rees" -u ${UID} -g ${GID} -G "wheel"  -d /home/${ADMIN} -s /usr/local/bin/zsh -o

  # Also creates the home directory
  mkdir -p /home/${ADMIN}/.ssh
  cp -Rp bootstrap/authorized_keys2 /home/${ADMIN}/.ssh

  chown -R ${ADMIN}:staff /home/${ADMIN}
  chmod 700 /home/${ADMIN}/.ssh
else
  echo "Admin (${ADMIN}) already exists."
fi

# Default from RootBSD
pw user show sean >/dev/null 2>&1
if [ $? -eq 0 ]; then
  pw user del sean
fi
