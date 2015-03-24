#!/bin/sh

cat <<EOF
ExtendedStatus on

LoadModule cgi_module libexec/apache24/mod_cgi.so
LoadModule userdir_module libexec/apache24/mod_userdir.so
Include etc/apache24/extra/httpd-default.conf

DirectoryIndex index.html index.htm

<VirtualHost _default_:80 ${IPV4_ADDR}:80 [${IPV6_PREFIX}::80]:80>
    ServerAdmin webmaster@${HOSTNAME}
    DocumentRoot /usr/local/www/apache24/data
    ServerName ${HOSTNAME}
    ServerAlias ${HOSTNAME}
    ErrorLog /var/log/httpd-error.log
    CustomLog /var/log/httpd-access.log common

    Include etc/apache24/extra/httpd-autoindex.conf 
    Include etc/apache24/extra/httpd-info.conf 
    Include etc/apache24/extra/httpd-userdir.conf 
</VirtualHost>

EOF

make_vhost() {
  username=$1
  domain=$2
  aliases=${3:-""}

  LOGDIR=/var/log/httpd/${domain}
  mkdir -p ${LOGDIR}

  cat <<EOF
<VirtualHost ${IPV4_ADDR}:80 [${IPV6_PREFIX}::80]:80>
    ServerAdmin webmaster@${domain}
    DocumentRoot /home/${username}/www/www.${domain}/data
    ServerName www.${domain}
    ServerAlias ${domain}
EOF

  for i in ${aliases}
  do
    echo "    ServerAlias ${i}"
  done

  cat <<EOF
    ErrorLog "|/usr/local/sbin/rotatelogs -l ${LOGDIR}/error.%Y-%m-%d.log 86400"
    CustomLog "|/usr/local/sbin/rotatelogs -l ${LOGDIR}/access.%Y-%m-%d.log 86400" combined

    ScriptAlias /cgi-bin/ /home/${username}/www/www.${domain}/cgi-bin/

    <Directory /home/${username}/www/www.${domain}/cgi-bin>
        Require all granted
    </Directory>
    <Directory /home/${username}/www/www.${domain}/data>
        Require all granted
        AllowOverride all
    </Directory>
</VirtualHost>

EOF

}

make_vhost srees dreamfire.net \
           "dreamfiresolutions.com www.dreamfiresolutions.com"
make_vhost srees seanrees.com
make_vhost srees rees.us

make_vhost brees bethrees.com

make_vhost myles test.zithora.com
