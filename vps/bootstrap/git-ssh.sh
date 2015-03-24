#!/bin/sh

KEY=bootstrap/git.key

# Just in case.
chmod 600 ${KEY}

exec ssh -oStrictHostKeyChecking=no -i ${KEY} $@
