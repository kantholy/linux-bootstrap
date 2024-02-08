# Plesk Snippets

## edit chroot configuration

```bash
# make sure you are root!
cd ~

# download script - run once!
wget https://raw.githubusercontent.com/plesk/kb-scripts/master/update-chroot/update-chroot.sh
chmod +x update-chroot.sh

# to fix the bug where the backspace is not working in chroot, run the collowing:
# see: https://talk.plesk.com/threads/backspace-key-doesnt-work-when-logged-in-chroot-account.369235/
cp -rf /lib/terminfo /var/www/vhosts/chroot/lib/terminfo
cp -rf /usr/share/terminfo/ /var/www/vhosts/chroot/usr/share/terminfo/
cp /etc/inputrc /var/www/vhosts/chroot/etc/inputrc

# to add apps, run:
./update_chroot.sh --add git
./update_chroot.sh --add nano
./update_chroot.sh --apply all

# to rebuild all the chroot template, run the following:
./update-chroot.sh --rebuild

```

## SFTP only jailed user

props to: <https://thunderysteak.github.io/sftp-user-chroot>

```bash
# make sure you are root!

# create group
addgroup sftponly

# change sftp subsystem to internal
sed -i 's|^Subsystem\s\+sftp.*|Subsystem sftp internal-sftp|' /etc/ssh/sshd_config

# add SFTP chroot Jail config to sshd_config
echo "
# SFTP chroot Jail
Match Group sftponly
    ChrootDirectory %h
    ForceCommand internal-sftp
    PermitTunnel no
    AllowAgentForwarding no
    AllowTcpForwarding no
    X11Forwarding no
" | sudo tee -a /etc/ssh/sshd_config >/dev/null

# Restart SSH service to apply changes
sudo systemctl restart ssh

```


## add jailed SFTP user

```bash
# make sure you are logged in as root!


read -p "Please input the user name: " input_username
# convert to lowercase
username=$(echo "$input_username" | tr '[:upper:]' '[:lower:]')
# add user: create homedir, disable SSH login and add to sftponly group
sudo useradd -m -d "/home/$username" -s /bin/false -G sftponly "$username"


```
