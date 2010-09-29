#!/bin/sh

ROUTER_IP=
ROUTER_PORT=
ROUTER_PASS=

nc -w 2 ${ROUTER_IP} ${ROUTER_PORT} <<EOF
${ROUTER_PASS}
wan adsl linedata near
wan adsl linedata far
wan adsl chandata
wan adsl perfdata
ip ifconfig
exit
EOF
