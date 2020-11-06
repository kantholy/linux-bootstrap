## Linux Bootstrap 

* this set of scripts is for debian/ubuntu based machines...

useful stuff:
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

# Ubuntu 18.04 add universe
sudo add-apt-repository universe


# proper SSH permissions
chmod g-w ~
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# generate SSH KEY
ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519 -C "$USER@$HOSTNAME"
printf "\nthis is your SSH public key:\n\n" && cat ~/.ssh/id_ed25519.pub && echo ""

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

## ufw
```bash
# based on https://www.linode.com/docs/guides/configure-firewall-with-ufw/
sudo apt-get -y install ufw
sudo sed -i 's/IPV6=no/IPV6=yes/g' /etc/default/ufw
# allow SSH (adjust the port if needed!)
sudo ufw allow 22/tcp

# allow HTTP + HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

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
# restart all the things
service rsyslog restart
```


## Ubuntu 18.04 MAC DHCP Reservation:

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

## Disable ipv6
```bash
sudo echo net.ipv6.conf.all.disable_ipv6 = 1 > /etc/sysctl.d/20-disable-ipv6.conf
sudo echo net.ipv6.conf.default.disable_ipv6 = 1 >> /etc/sysctl.d/20-disable-ipv6.conf
sudo echo net.ipv6.conf.lo.disable_ipv6 = 1 >> /etc/sysctl.d/20-disable-ipv6.conf

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

## Setup Time
```bash
sudo timedatectl set-ntp 1
sudo timedatectl set-timezone Europe/Berlin
sudo systemctl restart systemd-timesyncd
```
Custom NTP Server:
`vim /etc/systemd/timesyncd.conf`

* add `NTP=ntp.contoso.com` into the `[Time]` section

## SSH stuff
```bash
# proper SSH permissions
chmod g-w ~
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# generate new key
ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519 -C "$USER@$HOSTNAME"
```

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
