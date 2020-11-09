# Teamspeak 3 Linux Server

## Installation
```bash

# inspired by
# https://www.bennetrichter.de/anleitungen/teamspeak3-server-linux/
# https://unequal.de/teamspeak-3-server-installieren-linux/


# add new user
adduser --disabled-login --gecos "" ts3 --home /opt/ts3

# login as ts3 server
su ts3
cd ~

# download
wget https://files.teamspeak-services.com/releases/server/3.12.1/teamspeak3-server_linux_amd64-3.12.1.tar.bz2

# extract to current folder
tar --strip-components=1 -xf teamspeak3-server_linux_amd64-3.12.1.tar.bz2
# remove download
rm teamspeak3-server_linux_amd64-3.12.1.tar.bz2

# go to folder
cd teamspeak3-server_linux_amd64

# accept license
touch .ts3server_license_accepted

# create teamspeak ufw application profile
echo '[teamspeak]
title=ts3
description=TS3-Server
ports=9987:9992/udp|9999:10000/udp|30033/tcp' | sudo tee /etc/ufw/applications.d/teamspeak

# enable application
ufw allow teamspeak

# first start: 
/opt/ts3/ts3server_minimal_runscript.sh

#
# MAKE SURE YOU NOTE THE ADMIN ACCOUNT + PW on first start!
#
```

## Start

to start the server manually and get the status, just run the startscript:
```bash
# ONLY RUN THIS WHEN LOGGED IN AS ts3 USER
/opt/ts3/ts3server_startscript.sh start
/opt/ts3/ts3server_startscript.sh status


```

to automatically start the server, you could run the startscript at `@reboot` with crontab

```bash
# -> crontab -e
@reboot /opt/ts3/ts3server_startscript.sh start
```

or simply use the service file
```bash
echo '[Unit]
Description=TeamSpeak 3 Server
After=network.target
[Service]
WorkingDirectory=/opt/ts3/
User=ts3
Group=ts3
Type=forking
ExecStart=/opt/ts3/ts3server_startscript.sh start inifile=ts3server.ini
ExecStop=/opt/ts3/ts3server_startscript.sh stop
PIDFile=/opt/ts3/ts3server.pid
RestartSec=15
Restart=always
[Install]
WantedBy=multi-user.target' | sudo tee /lib/systemd/system/teamspeak.service

# enable and start the service
sudo systemctl enable teamspeak.service
sudo systemctl start teamspeak.service

# check if the server is running
sudo service teamspeak status
``` 