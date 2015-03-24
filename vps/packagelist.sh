#!/bin/sh

cat /dev/null > all-packages

cat bootstrap/packages >> all-packages
for i in services/*
do
  if [ -f ${i}/packages ]; then
    cat ${i}/packages >> all-packages
  fi
done
