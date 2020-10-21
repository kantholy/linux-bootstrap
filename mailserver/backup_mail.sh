#!/bin/bash

BACKUP_LOCATION='/srv/backup' # no trailing slash!
BACKUP_NAME='mail'

KEEP_DAILY=30
KEEP_WEEKLY=8
KEEP_MONTHLY=4

#----------------------------------------------------------
# PRE FLIGHT CHECKS
COLOR_GREEN='\033[1;32m'
COLOR_RED='\033[0;31m'
COLOR_RESET='\033[0m'

function log() {
  NOW=`date '+%Y-%m-%d %H:%M:%S'`
  printf "${COLOR_GREEN}${NOW} | ${1}${COLOR_RESET}\n"
}

function error() {

  NOW=`date '+%Y-%m-%d %H:%M:%S'`
  echo "${COLOR_RED}${NOW} | ${1}${COLOR_RESET}\n";
  exit 1
}



if [[ "$(whoami)" != 'root' ]]; then
    error "!! You must be root to do this. !!"
fi

if [[ ! ${BACKUP_LOCATION} =~ ^/ ]]; then
  error "!! Backup directory needs to be given as absolute path (starting with /)."
fi

if [[ -f ${BACKUP_LOCATION} ]]; then
  error "!! ${BACKUP_LOCATION} is a file!"
fi

#----------------------------------------------------------
# HERE WE GO!

DATE=$(date +"%Y-%m-%d_%H.%M.%S")

suffix=''

if [[ "$(date +"%d")" -eq "01" ]]; then
    SUFFIX='.WEEK'
fi

if [[ "$(date +"%w")" -eq "01" ]]; then
    SUFFIX='.MONTH'
fi

BACKUP_DIR="mail__$DATE$SUFFIX"

TARGET=$BACKUP_LOCATION/$BACKUP_DIR

#----------------------------------------------------------
log "creating backup dir: ${TARGET}"
mkdir -p $TARGET
chmod 600 $TARGET

#----------------------------------------------------------
log "backing up /etc/mailname..."

cp --parents /etc/mailname $TARGET
echo "  RETURNED: $?"

#----------------------------------------------------------
log "backing up mysql..."

mkdir $TARGET/mysql
mysqldump --databases vmail > $TARGET/mysql/vmail.sql
echo "  RETURNED: $?"

#----------------------------------------------------------
log "backing up mailboxes..."

mkdir $TARGET/mail

# export to tmp dir with proper permission
TMP_DIR=`mktemp -d`
chown -R vmail:vmail $TMP_DIR

for user in `doveadm user "*"`; do
    MAIL_TLD=${user#*@}
    MAIL_USR=${user%%@*}

    echo "> backing up $user..." 

    doveadm backup -n inbox -f -u $user "maildir:$TMP_DIR/$MAIL_TLD/$MAIL_USR:LAYOUT=fs"

    echo "  RETURNED: $?"
done

# then copy to actual backup dir!
cp -pr $TMP_DIR/* $TARGET/mail
# remove tmp
rm -r $TMP_DIR

# oldschool: cp -prv --parents /var/vmail/* $TARGET

#----------------------------------------------------------
log "backup up acme.sh certificates..."

find /etc/acme.sh -name '*.pem' | xargs cp --parents -t $TARGET
echo "  RETURNED: $?"

#----------------------------------------------------------
log "backup up dovecot config..."

cp --parents /etc/dovecot/dh4096.pem $TARGET
find /etc/dovecot -name '*.conf' | xargs cp --parents -t $TARGET
echo "  RETURNED: $?"

#----------------------------------------------------------
log "backup up postfix config..."

cp --parents /etc/postfix/dh2048.pem $TARGET
cp --parents /etc/postfix/submission_header_cleanup $TARGET
cp --parents /etc/postfix/without_ptr $TARGET
find /etc/postfix -name '*.cf' | xargs cp --parents -t $TARGET
echo "  RETURNED: $?"

#----------------------------------------------------------
log "backup up rspam config..."

find /etc/rspamd/local.d/ -name '*.map' | xargs cp --parents -t $TARGET
echo "  RETURNED: $?"

#----------------------------------------------------------
log "backup up dkim config..."

cp -r --parents /var/lib/rspamd/dkim $TARGET
find /etc/rspamd/local.d/ -name '*.conf' | xargs cp --parents -t $TARGET
echo "  RETURNED: $?"


#----------------------------------------------------------
log "compressing archive config..."

pushd $BACKUP_LOCATION >> /dev/null

tar -czf $TARGET.tgz $BACKUP_DIR --atime-preserve --preserve-permissions
echo "  RETURNED: $?" 
echo ""

popd >> /dev/null

#remove folder after compressing
rm -r $TARGET


#------------------------------------------------------------------------------
# CLEANUP

# find ${BACKUP_LOCATION}/*.tgz -maxdepth 0 -mmin +$((${1}*60*24)) -exec rm -rvf {} \

log " -- FERTIG --"
