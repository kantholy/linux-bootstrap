
# copycat from https://oitibs.com/debian-jessie-dynamic-motd/
# install figlet to enable ASCII art
sudo apt-get install figlet
# create directory
mkdir /etc/update-motd.d/
# change to new directory
cd /etc/update-motd.d/
# download dynamic files
wget https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/motd/00-header
wget https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/motd/10-sysinfo
wget https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/motd/20-updates
wget https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/motd/90-footer
# make files executable
chmod +x /etc/update-motd.d/*
# remove MOTD file
rm /etc/motd
# symlink dynamic MOTD file
ln -s /var/run/motd /etc/motd
