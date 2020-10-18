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

pause 'Press [Enter] key to continue...'


hostnamectl set-hostname --static mail
echo $hostname > /etc/mailname

apt -yq update
apt -yq upgrade

# -----------------------------------------------------------------------------
log "installing unbound..."
apt -yq install unbound resolvconf


echo "nameserver 127.0.0.1" >> /etc/resolv.conf

# -----------------------------------------------------------------------------
# https://thomas-leister.de/mailserver-debian-buster/#erstkonfiguration-nginx-webserver

log "installing nginx..."
apt -yq install nginx wget
cd /etc/nginx/sites-available/

wget https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/nginx/sites-available/setup
mv setup mail

ln -s /etc/nginx/sites-available/mail /etc/nginx/sites-enabled/mail


# -----------------------------------------------------------------------------
# https://thomas-leister.de/mailserver-debian-buster/#beantragung-der-tls-zertifikate-via-let-s-encrypt

log "installing acme.sh..."
cd ~
curl https://get.acme.sh | sh
source ~/.profile


log "configuring SSL certificates using acme.sh..."
acme.sh --issue --nginx -d mail.$domain -d imap.$domain -d smtp.$domain -d autoconfig.$domain

mkdir -p /etc/acme.sh/mail.$domain


mkdir -p /etc/acme.sh/mail.$domain
acme.sh --install-cert -d mail.$domain \
    --key-file       /etc/acme.sh/mail.$domain/privkey.pem  \
    --fullchain-file /etc/acme.sh/mail.$domain/fullchain.pem \
    --reloadcmd     "systemctl reload nginx; systemctl restart dovecot; systemctl restart postfix;"

 acme.sh --install-cronjob


# -----------------------------------------------------------------------------
# https://thomas-leister.de/mailserver-debian-buster/#mysql-datenbank-einrichten

log "installing MariaDB"
apt -yq install mariadb-server

mysql -e "grant select on vmail.* to 'vmail'@'localhost' identified by '$vmail_password';"


# -----------------------------------------------------------------------------
# https://thomas-leister.de/mailserver-debian-buster/#vmail-benutzer-und-verzeichnis-einrichten

log "setting up vmail..."
useradd --create-home --home-dir /var/vmail --user-group --shell /usr/sbin/nologin vmail

mkdir /var/vmail/mailboxes
mkdir -p /var/vmail/sieve/global
chown -R vmail /var/vmail
chgrp -R vmail /var/vmail
chmod -R 770 /var/vmail

# -----------------------------------------------
# https://thomas-leister.de/mailserver-debian-buster/#dovecot-installieren-und-konfigurieren

log "installing dovecot..."
apt -yq install dovecot-core dovecot-imapd dovecot-lmtpd dovecot-mysql dovecot-sieve dovecot-managesieved

systemctl stop dovecot

rm -r /etc/dovecot/*
cd /etc/dovecot

wget https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/dovecot/dovecot.conf
wget https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/dovecot/dovecot-sql.conf

chmod 440 dovecot-sql.conf

cd /var/vmail/sieve/global

wget https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/dovecot/sieve/global/learn-ham.sieve
wget https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/dovecot/sieve/global/learn-spam.sieve
wget https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/dovecot/sieve/global/spam-global.sieve


log "generating Diffie-Hellmann Parameter - this could take a while!"
apt -yq install havaged
openssl dhparam -out /etc/dovecot/dh4096.pem 4096 

# -----------------------------------------------
# https://thomas-leister.de/mailserver-debian-buster/#postfix-installieren-und-konfigurieren

log "installing postfix..."
apt -yq install postfix postfix-mysql
systemctl stop postfix

cd /etc/postfix
rm -r sasl
rm master.cf main.cf.proto master.cf.proto

wget https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/postfix/main.cf
wget https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/postfix/master.cf
wget https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/postfix/submission_header_cleanup

openssl dhparam -out /etc/postfix/dh2048.pem 2048


mkdir /etc/postfix/sql

wget https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/postfix/sql/accounts.cf
wget https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/postfix/sql/aliases.cf
wget https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/postfix/sql/domains.cf
wget https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/postfix/sql/recipient-access.cf
wget https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/postfix/sql/sender-login-maps.cf
wget https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/postfix/sql/tls-policy.cf

chown -R root:postfix /etc/postfix/sql
chmod g+x /etc/postfix/sql

touch /etc/postfix/without_ptr

postmap /etc/postfix/without_ptr
systemctl reload postfix

newaliases



# -----------------------------------------------
# https://thomas-leister.de/mailserver-debian-buster/#rspamd-1

log "installing rpamd..."

apt -yq install lsb-release wget
wget -O- https://rspamd.com/apt-stable/gpg.key | apt-key add -
echo "deb http://rspamd.com/apt-stable/ $(lsb_release -c -s) main" > /etc/apt/sources.list.d/rspamd.list
echo "deb-src http://rspamd.com/apt-stable/ $(lsb_release -c -s) main" >> /etc/apt/sources.list.d/rspamd.list


apt update
apt install rspamd redis-server
systemctl stop rspamd

touch /etc/rpsamd/local.d/whitelist_ip.map
touch /etc/rpsamd/local.d/whitelist_from.map
touch /etc/rpsamd/local.d/blacklist_ip.map
touch /etc/rpsamd/local.d/blacklist_from.map

mkdir /var/lib/rspamd/dkim/
rspamadm dkim_keygen -b 2048 -s 2020 -k /var/lib/rspamd/dkim/2020.key > /var/lib/rspamd/dkim/2020.txt
chown -R _rspamd:_rspamd /var/lib/rspamd/dkim
chmod 440 /var/lib/rspamd/dkim/*


cat /var/lib/rspamd/dkim/2020.txt

cp -R /etc/rspamd/local.d/dkim_signing.conf /etc/rspamd/local.d/arc.conf


# :: setup initial domain and user ::

mysql -u vmail -p$db_pass -e "insert into vmail.domains (domain) values ('$domain');"

hash=`openssl passwd -6 $postmaster_password`
hash="{SHA512-CRYPT}$hash"

mysql -u vmail -p$db_pass -e "insert into vmail.accounts (username, domain, password, quota, enabled, sendonly) values ('postmaster', '$domain', '$hash', 2048, true, false);"

# -----------------------------------------------
# :: start all the things ::

systemctl start rspamd
systemctl start dovecot
systemctl start postfix
