#!/bin/sh
cat <<EOF
ext_if="${NETIF}"
int_if="${INTIF}"

set block-policy return
set loginterface \$ext_if

table <firewall> const { self }
table <rfc1918> const { 192.168.0.0/16, 172.16.0.0/12, 10.0.0.0/8 }

set skip on lo

# scrub incoming packets
scrub in all

# vpn nat
nat on \$ext_if inet from !(\$ext_if) -> (\$ext_if:0)

# vpn
pass quick on tun0

# private network
#pass quick on \$int_if

# default deny
block all

# block rfc1918
block drop in on \$ext_if from <rfc1918> to any
block drop in on \$ext_if from any to <rfc1918>

# pass icmp
pass in inet proto icmp all keep state
pass in quick proto ipv6-icmp from any to any
pass out quick proto ipv6-icmp from any to any

# pass
pass in on \$ext_if inet proto { tcp, udp } from any to any port { ssh, smtp, 35, domain, http } keep state
pass in on \$ext_if inet6 proto { tcp, udp } from any to any port { ssh, smtp, 35, domain, http } keep state

# OpenVPN
pass in on \$ext_if inet proto { tcp, udp } from any to any port { 1194 } keep state
pass in on \$ext_if inet6 proto { tcp, udp } from any to any port { 1194 } keep state

# allow outgoing traffic
pass out on \$ext_if proto tcp all modulate state flags S/SA
pass out on \$ext_if proto { udp, icmp } all keep state
pass out on \$ext_if inet6 proto { tcp udp ipv6-icmp } keep state
EOF
