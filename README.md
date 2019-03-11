## Linux Bootstrap 

* this set of scripts is for debian/ubuntu based machines...

useful stuff:
```bash
# force color prompt
sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/g' ~/.bashrc

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
* set `rocommunity public 10.0.0.0` (public = user, 10.0.0.0 = snmpd poller ip)
* set `sysLocation` and `sysContact`
