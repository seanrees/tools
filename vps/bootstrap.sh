#!/bin/sh

# Apply initial configuration.
bootstrap/config.sh

echo -n "Stage 2.1: Setting up pkgng"
pkg

rm -f /etc/pkg/FreeBSD.conf
cp -Rp local-etc/pkg /usr/local/etc

echo -n "Stage 2.2: Installing base packages"
pkg install $(cat bootstrap/packages)

# Create base users.
bootstrap/users.sh

# Transition over to the git version of this tree.
bootstrap/to_git.sh
