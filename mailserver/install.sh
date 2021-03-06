#!/bin/bash
# -----------------------------------------------------------------------------
# heavily inspired by https://thomas-leister.de/mailserver-debian-buster/
# please support him! https://thomas-leister.de/en/donate/
# -----------------------------------------------------------------------------

if [ `whoami` != 'root' ]
  then
    echo "!! You must be root to do this. !!"
    exit
fi


function pause(){
   read -p "$*"
}

function log() {
   echo `date '+%Y-%m-%d %H:%M:%S'` " INFO:" $1
}


echo -n "ENTER DOMAIN NAME (domain.tld): "
read domain

echo -n "ENTER HOSTNAME (host.domain.tld): "
read hostname

echo -n "ENTER vmail database Password: "
read vmail_password

echo -n "ENTER postmaster@$domain Password: "
read postmaster_password

echo -n "ENTER rpamd Password: "
read rspamd_password


# -----------------------------------------------------------------------------
# :: LETS START ::

echo "--------------------------------------
  Domain              : $domain
  Server Hostname     : $hostname
  vmail Password      : $vmail_password
  Postmaster Password : $postmaster_password
  rspamd Password     : $rspamd_password
--------------------------------------"

pause 'Press [Enter] key to continue...'


hostnamectl set-hostname --static $hostname
echo $hostname > /etc/mailname

apt -qq update
apt -qq upgrade

# -----------------------------------------------------------------------------
log "installing unbound..."
apt -qq install resolvconf


echo "nameserver 127.0.0.1" >> /etc/resolv.conf

# -----------------------------------------------------------------------------
# https://thomas-leister.de/mailserver-debian-buster/#erstkonfiguration-nginx-webserver

log "installing nginx..."
apt -qq install nginx wget

mkdir /var/www/mail
cd /var/www/mail
wget -q https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/nginx/mail/index.html



cd /etc/nginx/sites-available/

wget https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/nginx/sites-available/setup
mv setup mail


sed -i "s/domain.tld/$domain/g" mail

ln -s /etc/nginx/sites-available/mail /etc/nginx/sites-enabled/mail

service nginx reload

# -----------------------------------------------------------------------------
# https://thomas-leister.de/mailserver-debian-buster/#beantragung-der-tls-zertifikate-via-let-s-encrypt

log "installing acme.sh..."
cd ~
apt -qq install curl
curl https://get.acme.sh | sh
source ~/.profile


log "configuring SSL certificates using acme.sh..."
acme.sh --issue --nginx -d mail.$domain

mkdir -p /etc/acme.sh/mail.$domain


acme.sh --install-cert -d mail.$domain \
    --key-file       /etc/acme.sh/mail.$domain/privkey.pem  \
    --fullchain-file /etc/acme.sh/mail.$domain/fullchain.pem \
    --reloadcmd     "systemctl reload nginx; systemctl restart dovecot; systemctl restart postfix;"

acme.sh --install-cronjob


# -----------------------------------------------------------------------------
# https://thomas-leister.de/mailserver-debian-buster/#mysql-datenbank-einrichten

log "installing MariaDB"
apt -qq install mariadb-server

wget https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/database.sql
mysql < database.sql
rm database.sql
mysql -e "grant select on vmail.* to 'vmail'@'localhost' identified by '$vmail_password';"


# -----------------------------------------------------------------------------
# https://thomas-leister.de/mailserver-debian-buster/#vmail-benutzer-und-verzeichnis-einrichten

log "setting up vmail..."
useradd --create-home --home-dir /var/vmail --user-group --shell /usr/sbin/nologin vmail

mkdir -p /var/vmail/sieve/global
chown -R vmail /var/vmail
chgrp -R vmail /var/vmail
chmod -R 770 /var/vmail

# -----------------------------------------------
# https://thomas-leister.de/mailserver-debian-buster/#dovecot-installieren-und-konfigurieren

log "installing dovecot..."

apt -qq install curl apt-transport-https

curl https://repo.dovecot.org/DOVECOT-REPO-GPG | gpg --import
gpg --export ED409DA1 > /etc/apt/trusted.gpg.d/dovecot.gpg
echo deb https://repo.dovecot.org/ce-2.3-latest/ubuntu/bionic bionic main > /etc/apt/sources.list.d/dovecot.list

apt -qq install dovecot-core dovecot-imapd dovecot-lmtpd dovecot-mysql dovecot-sieve dovecot-managesieved

systemctl stop dovecot

rm -r /etc/dovecot/*
cd /etc/dovecot

wget -q https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/dovecot/dovecot.conf
wget -q https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/dovecot/dovecot-sql.conf

sed -i "s/domain.tld/$domain/g" dovecot.conf

chmod 440 dovecot-sql.conf

cd /var/vmail/sieve/global

wget -q https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/dovecot/sieve/global/learn-ham.sieve
wget -q https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/dovecot/sieve/global/learn-spam.sieve
wget -q https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/dovecot/sieve/global/spam-global.sieve


log "generating Diffie-Hellmann Parameter - this could take a while!"
openssl dhparam -out /etc/dovecot/dh4096.pem 4096 

# -----------------------------------------------
# https://thomas-leister.de/mailserver-debian-buster/#postfix-installieren-und-konfigurieren

log "installing postfix..."
apt -qq install postfix postfix-mysql
systemctl stop postfix

cd /etc/postfix
rm -r sasl
mv main.cf main.cf.bak
rm master.cf main.cf.proto master.cf.proto

wget -q https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/postfix/main.cf
wget -q https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/postfix/master.cf
wget -q https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/postfix/header_checks
wget -q https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/postfix/submission_header_cleanup

openssl dhparam -out /etc/postfix/dh2048.pem 2048

sed -i "s/domain.tld/$domain/g" main.cf

mkdir /etc/postfix/sql
cd /etc/postfix/sql

wget -q https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/postfix/sql/accounts.cf
wget -q https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/postfix/sql/aliases.cf
wget -q https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/postfix/sql/domains.cf
wget -q https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/postfix/sql/recipient-access.cf
wget -q https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/postfix/sql/sender-login-maps.cf
wget -q https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/postfix/sql/tls-policy.cf

chown -R root:postfix /etc/postfix/sql
chmod g+x /etc/postfix/sql

touch /etc/postfix/without_ptr

postmap /etc/postfix/without_ptr
systemctl reload postfix

newaliases



# -----------------------------------------------
# https://thomas-leister.de/mailserver-debian-buster/#rspamd-1

log "installing rpamd..."

apt -qq install lsb-release wget gnupg2

apt-get install -qq lsb-release # optional
CODENAME=`lsb_release -c -s`
wget -O- https://rspamd.com/apt-stable/gpg.key | apt-key add -
echo "deb [arch=amd64] http://rspamd.com/apt-stable/ $CODENAME main" > /etc/apt/sources.list.d/rspamd.list
echo "deb-src [arch=amd64] http://rspamd.com/apt-stable/ $CODENAME main" >> /etc/apt/sources.list.d/rspamd.list
apt-get update
apt-get -qq --no-install-recommends install rspamd


apt -qq install redis-server
systemctl stop rspamd

touch /etc/rspamd/local.d/whitelist_ip.map
touch /etc/rspamd/local.d/whitelist_from.map
touch /etc/rspamd/local.d/blacklist_ip.map
touch /etc/rspamd/local.d/blacklist_from.map

mkdir /var/lib/rspamd/dkim/
rspamadm dkim_keygen -b 2048 -s 2020 -k /var/lib/rspamd/dkim/2020.key > /var/lib/rspamd/dkim/2020.txt
chown -R _rspamd:_rspamd /var/lib/rspamd/dkim
chmod 440 /var/lib/rspamd/dkim/*


cat /var/lib/rspamd/dkim/2020.txt

cd /etc/rspamd/local.d/

wget -q -O classifier-bayes.conf https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/rspamd/local.d/classifier-bayes.conf
wget -q -O dkim_signing.conf https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/rspamd/local.d/dkim_signing.conf
wget -q -O logging.inc https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/rspamd/local.d/logging.inc
wget -q -O milter_headers.conf https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/rspamd/local.d/milter_headers.conf
wget -q -O multimap.conf https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/rspamd/local.d/multimap.conf
wget -q -O redis.conf https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/rspamd/local.d/redis.conf

cd /etc/rspamd/override.d/

wget -q -O classifier-bayes.conf https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/rspamd/override.d/classifier-bayes.conf


cp -R /etc/rspamd/local.d/dkim_signing.conf /etc/rspamd/local.d/arc.conf

log "installing clamav-milter"
apt -qq install clamav-milter clamav-daemon
cd /etc/clamav/
rm clamav-milter.conf
wget -q https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/mailserver/clamav/clamav-milter.cf

systemctl enable clamav-daemon
service clamav-daemon start
service clamav-milter start


# :: setup initial domain and user ::

mysql -e "insert into vmail.domains (domain) values ('$domain');"

hash=`openssl passwd -6 $postmaster_password`
hash="{SHA512-CRYPT}$hash"

mysql -e "insert into vmail.accounts (username, domain, password, quota, enabled, sendonly) values ('postmaster', '$domain', '$hash', 2048, true, false);"

# -----------------------------------------------
# :: start all the things ::

systemctl start rspamd
systemctl start dovecot
systemctl start postfix
