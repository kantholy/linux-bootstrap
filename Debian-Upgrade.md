# Debian Upgrade Scripts

This is a collection of commands to help me with updating to never distro versions.

**PLEASE RUN COMMANDS ONE BY ONE!**

## from 10.x (Buster) to 11.x (Bullseye)

```bash
###############################################################################
# DISCLAIMER:
# 
# MAKE SURE THE SYSTEM IS BACKED UP FIRST!!!
#
###############################################################################
# Step 1: show current versions

cat /etc/os-release
cat /etc/debian_version

# show Linux Kernel Version
uname -mrs

# show installed packages
apt list '?narrow(?installed, ?not(?origin(Debian)))'

###############################################################################
# STEP 2: make sure all packages are up to date first

sudo apt update
sudo apt upgrade
sudo full-upgrade
sudo apt --purge autoremove

# reboot when done!
sudo systemctl reboot

###############################################################################
# STEP 3: update /etc/apt/sources.list

# show current file
cat /etc/apt/sources.list
# backup
source /etc/os-release
sudo cp -v /etc/apt/sources.list "/root/backup-$VERSION_ID-$VERSION_CODENAME--sources.list"


# adjust /etc/apt/sources.list to the bullseye sources
sudo sed -i'.bak' 's/buster/bullseye/g' /etc/apt/sources.list

# you can also use the following lines
#
# deb http://deb.debian.org/debian/ bullseye main
# deb-src http://deb.debian.org/debian/ bullseye main
#
# deb http://deb.debian.org/debian-security/ bullseye-security main
# deb-src http://deb.debian.org/debian-security/ bullseye-security main
#
# deb http://deb.debian.org/debian/ bullseye-updates main
# deb-src http://deb.debian.org/debian/ bullseye-updates main


###############################################################################
# STEP 4: UPGRADE time

# update the lists
sudo apt update

## IF you get some error messages that the APT sources are not found, make sure the URLs are valid
# -> the debian-security updates may be the issue here!

# update the necessary updates first
sudo apt upgrade --without-new-pkgs

# HEADS UP: multiple prompts will appear, make sure to read them carefully and response accordingly
# apt-listchanges needs to be quit with "q"
# my recommandation: keep all local versions of modified config files - you modified them because of something!

# do the actual distro upgrades
sudo apt full-upgrade

# doublecheck to make sure you are sure that sshd config is not f**ked up:
sudo sshd -t
# otherwise, edit it and test again:
nano /etc/ssh/sshd_config

###############################################################################
# STEP 5: Reboot

sudo systemctl reboot


# after reboot, make sure everything is well:

# check Kernel:
uname -mrs
# check Debian Version:
cat /etc/os-release

## DONE!!
```


## from 11.x (bullseye) to 12.x (bookworm)

```bash
###############################################################################
# DISCLAIMER:
# 
# MAKE SURE THE SYSTEM IS BACKED UP FIRST!!!
#
###############################################################################
# Step 1: show current versions

cat /etc/os-release
cat /etc/debian_version

# show Linux Kernel Version
uname -mrs

# show installed packages
apt list '?narrow(?installed, ?not(?origin(Debian)))'

###############################################################################
# STEP 2: make sure all packages are up to date first

sudo apt update
sudo apt upgrade
sudo full-upgrade
sudo apt --purge autoremove

# reboot when done!
sudo systemctl reboot

###############################################################################
# STEP 3: update /etc/apt/sources.list

# show current file
cat /etc/apt/sources.list
# backup
source /etc/os-release
sudo cp -v /etc/apt/sources.list "/root/backup-$VERSION_ID-$VERSION_CODENAME--sources.list"


# adjust /etc/apt/sources.list to the bullseye sources
# this will simply replace buster with bullseye in the config file
sudo sed -i'.bak' 's/buster/bullseye/g' /etc/apt/sources.list

# you can also use the following lines for reference
# deb http://deb.debian.org/debian bookworm main
# deb http://deb.debian.org/debian bookworm-updates main
# deb http://security.debian.org/debian-security bookworm-security main


###############################################################################
# STEP 4: UPGRADE time

# update the lists
sudo apt update


# update the necessary updates first
sudo apt upgrade --without-new-pkgs

# HEADS UP: multiple prompts will appear, make sure to read them carefully and response accordingly
# apt-listchanges needs to be quit with "q"
# my recommandation: keep all local versions of modified config files - you modified them because of something!

# do the actual distro upgrades
sudo apt full-upgrade

# doublecheck to make sure you are sure that sshd config is not f**ked up:
sudo sshd -t
# otherwise, edit it and test again:
nano /etc/ssh/sshd_config

###############################################################################
# STEP 5: Reboot

sudo systemctl reboot


# after reboot, make sure everything is well:

# check Kernel:
uname -mrs
# check Debian Version:
cat /etc/os-release

## DONE!!
```
