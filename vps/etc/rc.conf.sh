#!/bin/sh
cat <<EOF
hostname="${HOSTNAME}"

# Connectivity
ifconfig_${NETIF}="${IPV4} -tso4"
ifconfig_${NETIF}_ipv6="${IPV6}"

# Private interface.
ifconfig_${INTIF}="${IPV4_INTIF} -tso4"

# IPv6
EOF

# IPv6 aliases.
count=0
for i in ${IPV6_ALIASES}
do
  echo "ifconfig_${NETIF}_alias${count}=\"inet6 ${IPV6_PREFIX}${i}\""
  count=`expr ${count} + 1`
done

cat <<EOF

# Gateway
gateway_enable="YES"
pf_enable="YES"
sshd_enable="YES"
ntpd_enable="YES"
EOF
