## Linux Bootstrap 

* this set of scripts is for debian/ubuntu based machines...

## bash
```bash
# force color prompt
sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/g' ~/.bashrc

echo "# quick folder view: list folders + files, human readable!" | tee -a ~/.bashrc
echo "alias l='ls -lh --group-directories-first'" | tee -a ~/.bashrc

source ~/.bashrc

# copy .bashrc to root
sudo cp ~/.bashrc /root/.bashrc
# red prompt for root user
sudo sed -i 's/;32m/;31m/g' /root/.bashrc

# sudo without password
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers
```

## SSH

```bash
# proper SSH permissions
chmod g-w ~
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# generate SSH KEY
ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519 -C "$USER@$HOSTNAME"
printf "\nthis is your SSH public key:\n\n" && cat ~/.ssh/id_ed25519.pub && echo ""

# Issue File
echo "\S{PRETTY_NAME} - Name: \n - IP: \4{eth0}" | sudo tee /etc/issue

# clean and secure SSH config:
sudo wget -q -O /etc/ssh/banner https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/etc/ssh/banner
sudo wget -q -O /etc/ssh/sshd_config https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/etc/ssh/sshd_config

# ############################################################################
#
# -- optional settings !! READ BEFORE YOU ACT !!
# 
# to move the SSH Port away from default:
sudo sed -i 's/Port 22/Port 2222/' /etc/ssh/sshd_config
#
# to allow only the current user to connect via SSH
sudo sed -i "s/#AllowUsers username/AllowUsers $USER/" /etc/ssh/sshd_config
#
# to allow root login:
sudo sed -i 's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
#
# ############################################################################


```

## logwatch

```bash
# install logwatch
sudo apt -yq install logwatch

echo '# make sure you set a valid MailTo
MailTo = 
MailFrom = root@localhost
Range = yesterday
Detail = Med
# less noise
Service = "-pam_unix"
Service = "-saslauthd"
Service = "-rsyslogd"' | sudo tee /etc/logwatch/conf/logwatch.conf

sudo sed -i "s/root@localhost/root@$HOSTNAME/" /etc/logwatch/conf/logwatch.conf

sudo nano /etc/logwatch/conf/logwatch.conf
```


## fail2ban
```bash
sudo apt -y install fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# harden fail2ban
sudo sed -i 's/bantime  = 10m/bantime  = 1h/' /etc/fail2ban/jail.local
sudo sed -i 's/findtime  = 10m/findtime  = 30m/' /etc/fail2ban/jail.local
sudo sed -i 's/maxretry = 5/maxretry = 3/' /etc/fail2ban/jail.local

echo "[Definition]
# This file overrides the default settings in /etc/fail2ban/fail2ban.conf
# Customizations should be written here so that updates do NOT overwrite them!

### Set logging options
## verbosity -- options: CRITICAL, ERROR (default), WARNING, NOTICE, INFO, DEBUG
loglevel = INFO
logtarget = /var/log/fail2ban.log

### Amount of time (in seconds) before HISTORY of bans are cleared.
dbpurgeage = 7d
" | sudo tee /etc/fail2ban/fail2ban.local

# SSH jail is enabled by default on debian based systems
# based on /etc/fail2ban/jail.d/defaults-debian.conf


# (optional)enable ufw fail2ban blocking:
cd /etc/fail2ban/filter.d/
sudo wget -q -O ufw-probe.conf https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/etc/fail2ban/filter.d/ufw-probe.conf
cd /etc/fail2ban/jail.d/
sudo wget -q -O ufw-probe.conf https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/etc/fail2ban/jail.d/ufw-probe.conf

sudo service fail2ban restart


# --fail2ban-status
# convenient function to get the status of all fail2ban jails
echo '

function fail2ban-status() {
  JAILS=($(fail2ban-client status | grep "Jail list" | sed -E "s/^[^:]+:[ \t]+//" | sed "s/,//g"))
  for JAIL in ${JAILS[@]}
  do
    fail2ban-client status $JAIL
  done
}' | sudo tee -a /root/.bashrc


# -- DEPRECATED/BUGGY -- 
# [must be fixed first]
# (optional) enable fail2ban honeypot
cd /etc/fail2ban/action.d/
sudo wget -q -O iptables-honeypot.conf https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/etc/fail2ban/action.d/iptables-honeypot.conf
cd /etc/fail2ban/filter.d/
sudo wget -q -O iptables-honeypot.conf https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/etc/fail2ban/filter.d/iptables-honeypot.conf
cd /etc/fail2ban/jail.d/
sudo wget -q -O iptables-honeypot.conf https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/etc/fail2ban/jail.d/iptables-honeypot.conf

sudo service fail2ban restart

```

## Docker

```bash
# remove old versions
sudo apt-get remove docker docker-engine docker.io containerd runc

# setup docker APT repo
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release
# Docker PGP
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
# add docker stable Repo
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# install docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# install docker-compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s | awk '{ print tolower($0) }')-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# install lazydocker - MUST BE RUN AS ROOT!
export DIR="/usr/local/bin"
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
```

## ufw
```bash
# based on https://www.linode.com/docs/guides/configure-firewall-with-ufw/
sudo apt-get -y install ufw
sudo sed -i 's/IPV6=no/IPV6=yes/g' /etc/default/ufw
# allow SSH (adjust the port if needed!)
sudo ufw allow 22/tcp

# (optional) allow HTTP + HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# (optional) allow FTP
sudo ufw allow 21/tcp
# (optional) allow SMTP
sudo ufw allow 25/tcp
sudo ufw allow 587/tcp
# (optional) allow IMAP + IMAPS
sudo ufw allow 143/tcp
sudo ufw allow 993/tcp

# (optional) allow POP3 (not recommended - use IMAP!)
#sudo ufw allow 110/tcp
#sudo ufw allow 995/tcp

# default rules
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw logging low

# enable ufw
sudo ufw disable
sudo ufw enable


# to check if ufw is setup properly:
sudo iptables -L -n
# to see if ufw is blocking something:
sudo dmesg
# make sure rsyslog is receiving the ufw stuff:
sudo sed -i 's/#module(load="imklog"/module(load="imklog"/' /etc/rsyslog.conf
# prevent spam to syslog
sudo sed -i 's/#& stop/\& stop/' /etc/rsyslog.d/20-ufw.conf
# restart all the things
sudo service rsyslog restart


### do delete some rules:
# 1. show numbered:
sudo ufw status numbered
# 2. pick and remove numbered rule
sudo ufw delete %NUMBER%
# 3. as the numbering changes, make sure you show the status numbered again
# !! before!! you delete more rules!
# - you have been warned!

#
# reset UFW in case something bad happend to your configuration
#
sudo ufw disable
sudo ufw reset
```


## Setup Time
```bash
sudo timedatectl set-ntp 1
sudo timedatectl set-timezone Europe/Berlin

# custom NTP server:
echo "[Time]
NTP=pool.ntp.org time.google.com time.cloudflare.com
FallbackNTP=ntp.ubuntu.com
#RootDistanceMaxSec=5
#PollIntervalMinSec=32
#PollIntervalMaxSec=2048
" | sudo tee /etc/systemd/timesyncd.conf

sudo systemctl restart systemd-timesyncd
```


## Ubuntu MAC DHCP Reservation:

add `dhcp-identifier: mac` after `dhcp4` in `/etc/netplan/xxx.yaml (cloud-init)`
```
network:
    renderer: networkd
    version: 2
    ethernets:
        nicdevicename:
            dhcp4: true
            dhcp-identifier: mac
```

## Setup bind9 DNS
```bash
# install bind9
sudo apt -y install bind9

pushd /etc/resolvconf/resolv.conf.d
sudo cp base base.bak
echo 'nameserver 127.0.0.1' | sudo tee base
sudo resolvconf -u
popd
```

## Disable IPv6
```bash
echo 'net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1' | sudo tee /etc/sysctl.d/20-disable-ipv6.conf

# reload the values
sudo sysctl --system

# verify if ipv6 is disable: output should be empty
sudo ip addr show | grep inet6

```
* Bug in Ubuntu 18.04: values are not set after reboot!
* add `@reboot sleep 10 && sysctl --system` to the cronjob: `crontab -e` (as root)

## Ubuntu remove cloud-init
```bash
echo 'datasource_list: [ None ]' | sudo -s tee /etc/cloud/cloud.cfg.d/90_dpkg.cfg
sudo apt-get purge cloud-init
sudo rm -rf /etc/cloud/; sudo rm -rf /var/lib/cloud/

sudo systemctl disable iscsid.service
sudo systemctl disable open-iscsi.service
```

## Ubuntu strip motd

```bash
sudo chmod 644 /etc/update-motd.d/10-help-text
sudo chmod 644 /etc/update-motd.d/50-motd-news
sudo chmod 644 /etc/update-motd.d/80-esm
sudo chmod 644 /etc/update-motd.d/80-livepatch
sudo chmod 644 /etc/update-motd.d/95-hwe-eol

# show figlet hostname on logon!
sudo apt install figlet
sudo echo \#\!/bin/sh > /etc/update-motd.d/05-hostname
sudo echo figlet $(hostname) >> /etc/update-motd.d/05-hostname
sudo chmod 755 /etc/update-motd.d/05-hostname
``` 

## Install SNMPD
```bash
sudo apt-get update
sudo apt-get install snmpd
```
* don't forget to configure snmpd: `vim /etc/snmp/snmpd.conf`
* set `agentAddress udp:161` (to listen at all interfaces)
* set `rocommunity public 10.0.0.0` (public = user, 10.0.0.0 = snmpd poller ip)
* set `sysLocation` and `sysContact`


## Setup Web Stack
```bash
# essentials
sudo apt install -y git unzip

# nginx
sudo apt install -y nginx

# PHP
sudo apt install software-properties-common
sudo add-apt-repository ppa:ondrej/php
sudo apt update
sudo apt install -y php7.4-cli php7.4-fpm php7.4-zip php7.4-mbstring php7.4-xml php7.4-curl php7.4-mysql

# PHP8
sudo apt install -y php8.1
sudo apt install -y php8.1-{mysql,cli,common,imap,ldap,xml,fpm,curl,mbstring,zip}

# php settings:
sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 256M/g' /etc/php/7.4/fpm/php.ini
sudo service php7.4-fpm restart >/dev/null

# composer installation
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
composer --version

# MariaDB
sudo apt install mariadb-server
sudo mysql_secure_installation
```

## Laravel Berechtigungen anpassen
```bash
# aktuellen User in die www-data Gruppe mit aufnehmen
sudo usermod -a -G www-data $USER
# Berechtigungen auf dem Laravel Projektverzeichnis anpassen
sudo chown -R $USER:www-data /www/XXX
```
