## Linux Bootstrap 

* this set of scripts is for debian/ubuntu based machines...

useful stuff:
```bash
# force color prompt
sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/g' ~/.bashrc

# copy .bashrc to root
sudo cp ~/.bashrc /root/.bashrc
# red prompt for root user
sudo sed -i 's/;32m/;31m/g' /root/.bashrc


# sudo without password
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers

# Ubuntu 18.04 add universe
sudo add-apt-repository universe
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

## Ubuntu 18.04 disable ipv6
```
echo net.ipv6.conf.all.disable_ipv6 = 1 > /etc/sysctl.d/20-disable-ipv6.conf
echo net.ipv6.conf.default.disable_ipv6 = 1 >> /etc/sysctl.d/20-disable-ipv6.conf
echo net.ipv6.conf.lo.disable_ipv6 = 1 >> /etc/sysctl.d/20-disable-ipv6.conf

# reload the values
sysctl --system

# verify if ipv6 is disable: output should be empty
ip addr show | grep inet6

```
* Bug in Ubuntu 18.04: values are not set after reboot!
* add `@reboot sleep 10 && sysctl --system` to the cronjob: `crontab -e` (as root)

## Ubuntu remove cloud-init
```
echo 'datasource_list: [ None ]' | sudo -s tee /etc/cloud/cloud.cfg.d/90_dpkg.cfg
sudo apt-get purge cloud-init
sudo rm -rf /etc/cloud/; sudo rm -rf /var/lib/cloud/

sudo systemctl disable iscsid.service
sudo systemctl disable open-iscsi.service
```

## Ubuntu strip motd

```
chmod 644 /etc/update-motd.d/10-help-text
chmod 644 /etc/update-motd.d/50-motd-news
chmod 644 /etc/update-motd.d/80-esm
chmod 644 /etc/update-motd.d/80-livepatch
chmod 644 /etc/update-motd.d/95-hwe-eol

echo \#\!/bin/sh > /etc/update-motd.d/05-hostname
echo figlet $(hostname) >> /etc/update-motd.d/05-hostname
chmod 755 /etc/update-motd.d/05-hostname
``` 

## Install SNMPD
```
apt-get update
apt-get install snmpd
```
* don't forget to configure snmpd: `vim /etc/snmp/snmpd.conf`
* set `agentAddress udp:161` (to listen at all interfaces)
* set `rocommunity public 10.0.0.0` (public = user, 10.0.0.0 = snmpd poller ip)
* set `sysLocation` and `sysContact`

## Setup NTP
```
timedatectl set-ntp no
apt-get install ntp
#show peers:
ntpq -p
```
* edit peer list (add custom ntp server): `vim /etc/ntp.conf`:
* add `pool ntp.contoso.com` before default pools (feel free to remove/comment out defaults)
