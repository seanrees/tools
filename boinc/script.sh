#!/bin/sh

while true
do
./boincprom.py > /var/lib/prometheus/node-exporter/boinc.prom
sleep 60
done
