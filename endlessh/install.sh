#!/bin/bash

SSH_PORT=1122

if [ `whoami` != 'root' ]
  then
    echo "ERROR: You must be root to do this."
    exit
fi

cd /root

# check if endlessh is installed
if [ ! -f /usr/local/bin/endlessh ]; then
    wget -q -O endlessh.tar.gz https://salsa.debian.org/debian/endlessh/-/archive/debian/sid/endlessh-debian-sid.tar.gz
    tar -xf endlessh.tar.gz

    apt -y build-essential
    cd endlessh-debian-sid/
    make
    make install
fi

# doublecheck, otherwise exit!
if [ ! -f /usr/local/bin/endlessh ]; then
    echo "ERROR: UNABLE TO INSTALL endlessh"
    exit
fi

# install service file
wget -q -O /etc/systemd/system/endlessh.service https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/endlessh/endlessh.service

# make sure endlessh can run on ports lt 1024
setcap 'cap_net_bind_service=+ep' /usr/local/bin/endlessh
#sed -i "s/#AmbientCapabilities/AmbientCapabilities/" /lib/systemd/system/endlessh.service
#sed -i "s/PrivateUsers=/#PrivateUsers=/" /lib/systemd/system/endlessh.service
systemctl daemon-reload
systemctl enable endlessh

# stop endlessh after installing
service endlessh stop

# move SSH Port
sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config

# make sure the Port is 1122!
cat /etc/ssh/sshd_config | grep "Port $SSH_PORT"
if [ $? -ne 0 ]; then
    echo "ERROR: UNABLE TO CHANGE SSHD Port to $SSH_PORT. "
    exit
fi

# generate config file

mkdir -p /etc/endlessh

wget -q -O /etc/endlessh/config https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/endlessh/config

if [[ -f /etc/endlessh/config ]]; then
    echo "Port 22" > /etc/endlessh/config
    echo "Delay 10000" >> /etc/endlessh/config
    echo "MaxLineLength 32" >> /etc/endlessh/config
    echo "MaxClients 4096" >> /etc/endlessh/config
    echo "LogLevel 1" >> /etc/endlessh/config
    echo "BindFamily 4" >> /etc/endlessh/config
fi


# restart all the things!
service ssh stop && service endlessh start && service ssh start


service endlessh status
service ssh status