
# copycat from https://oitibs.com/debian-jessie-dynamic-motd/
# install figlet to enable ASCII art
sudo apt-get install figlet
# create directory
mkdir /etc/update-motd.d/
# change to new directory
cd /etc/update-motd.d/
# create dynamic files
touch 00-header && touch 10-sysinfo && touch 90-footer
# make files executable
chmod +x /etc/update-motd.d/*
# remove MOTD file
rm /etc/motd
# symlink dynamic MOTD file
ln -s /var/run/motd /etc/motd
