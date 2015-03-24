#!/bin/sh

cat <<EOF
::1                     localhost localhost.my.domain
127.0.0.1               localhost localhost.my.domain
${IPV4_ADDR}            ${HOSTNAME}
${IPV6_PREFIX}::53      ${HOSTNAME}
EOF
