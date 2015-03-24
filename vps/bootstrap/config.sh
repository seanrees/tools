#!/bin/sh

HOSTID=$(cat /etc/hostid)

if [ ! -z ${HOSTID} -a -f machines/${HOSTID} ];
then
  . machines/${HOSTID}
else
  echo "No configuration for this machine: ${HOSTID}"
  exit 1
fi

# Provide some synthetic variables that the configuration
# scrips can use.
IPV4_ADDR=$(/sbin/ifconfig ${NETIF} inet | grep inet | awk '{print $2}')

export IPV4_ADDR

echo "Configuring ${HOSTNAME}"

merge() {
  src=$1
  dst=$2

  for i in $(find ${src} -type f)
  do
    DEST=$(echo ${i} | sed s@${src}@${dst}@)

    # Create intermediary directories.
    mkdir -p $(dirname $DEST)

    echo $i | grep -q ".sh$"

    if [ $? -eq 0 ]; then
      DEST=$(echo ${DEST} | sed s/.sh$//)

      ${i} > ${DEST}
    else
      cp ${i} ${DEST}
      /usr/sbin/chown root:wheel ${DEST}
    fi
  done
}

mkdir -p /usr/local/etc

merge etc /etc
merge local-etc /usr/local/etc

cp -Rp root/* /root
cp -Rp root/.ssh/authorized_keys2 /root/.ssh
if [ -f /root/authorized_keys2 ]; then
  rm -f /root/authorized_keys2
fi

/usr/sbin/chown -R root:wheel /root
chmod 600 /root/sync/sync.key

# Misc.
for i in cron/*
do
  user=$(echo $i | sed s@cron/@@)
  crontab -u ${user} ${i}
done

rm -f /etc/localtime && ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Base ports
if [ -x /usr/local/sbin/pkg ]; then
  /usr/local/sbin/pkg update
  /usr/local/sbin/pkg upgrade -y
fi

# Setup services
mkdir -p /usr/local/etc/.vps_state  # Keeps state.
cat /dev/null > /etc/rc.conf.local
for service in ${SERVICES}
do
  service_dir=services/${service}

  # Install packages if not installed or we have a new version of
  # the service. We will simply let pkg resolve whether or not they're
  # installed.
  if [ -x /usr/local/sbin/pkg -a -f services/${service}/packages ]; then
    /usr/local/sbin/pkg install -y $(cat services/${service}/packages)
  fi

  # Setup configuration.
  if [ -d ${service_dir}/local-etc ]; then
    merge ${service_dir}/local-etc /usr/local/etc
  fi
  if [ -d ${service_dir}/local-www ]; then
    merge ${service_dir}/local-www /usr/local/www
  fi
  if [ -d ${service_dir}/etc ]; then
    merge ${service_dir}/etc /etc
  fi
  cat ${service_dir}/rc.conf.fragment >> /etc/rc.conf.local

  if [ -x ${service_dir}/post_config.sh ]; then
    ${service_dir}/post_config.sh
  fi

  # Rewrite the MOTD
  /etc/rc.d/motd start 2>&1 >/dev/null
done
