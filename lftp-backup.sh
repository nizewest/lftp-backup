#!/bin/bash

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin"
export PATH

# === SETTINGS ===

# -- Common --

COMMON_BACKUP_NAME="site"
COMMON_KEEP_DAYS=30
COMMON_DATE="$(date '+%Y-%m-%d')"
COMMON_MYSQLDUMP_PATH="$(which mysqldump)"
COMMON_FIND_PATH="$(which find)"
COMMON_TAR_PATH="$(which tar)"

# -- Local dirs --

LOCAL_BACKUP_DIR="/backups"
LOCAL_BACKUP_SITE_DIR="$LOCAL_BACKUP_DIR/$COMMON_BACKUP_NAME"
LOCAL_BACKUP_MYSQL_DIR="$LOCAL_BACKUP_SITE_DIR/mysql"
LOCAL_BACKUP_WWW_DIR="$LOCAL_BACKUP_SITE_DIR/www"
LOCAL_EXCLUDE_DIRS="--exclude=\"*/storage\" --exclude=\"*/cache\""

LOCAL_WWW_SOURCE_DIR="/var/www/$COMMON_BACKUP_NAME/"

# -- MySQL --

MYSQL_DB="site"
MYSQL_USER="site"
MYSQL_PASS="pass"

# -- LFTP --

LFTP_SERVER="server"
LFTP_USER="user"
LFTP_PASS="pass"
LFTP_BACKUP_DIR="/backups"
LFTP_BACKUP_SITE_DIR="$LFTP_BACKUP_DIR/$COMMON_BACKUP_NAME"

# === PROGRESS ===

echo "Starting $COMMON_BACKUP_NAME backup..."

echo "MySQL Dumping..."
$COMMON_MYSQLDUMP_PATH --opt --skip-add-locks -h localhost -u $MYSQL_USER -p$MYSQL_PASS $MYSQL_DB | gzip > $LOCAL_BACKUP_MYSQL_DIR/$COMMON_BACKUP_NAME\_$COMMON_DATE.sql.gz

echo "Deleting old MySQL backups..."
$COMMON_FIND_PATH $LOCAL_BACKUP_MYSQL_DIR/*.sql.gz -mtime +$COMMON_KEEP_DAYS
$COMMON_FIND_PATH $LOCAL_BACKUP_MYSQL_DIR/*.sql.gz -mtime +$COMMON_KEEP_DAYS -exec rm {} +

echo "TAR www..."
$COMMON_TAR_PATH -chzf $LOCAL_BACKUP_WWW_DIR/$COMMON_BACKUP_NAME\_$COMMON_DATE.tgz $LOCAL_EXCLUDE_DIRS $LOCAL_WWW_SOURCE_DIR

echo "Deleting old www backups..."
$COMMON_FIND_PATH $LOCAL_BACKUP_WWW_DIR/*.tgz -mtime +$COMMON_KEEP_DAYS
$COMMON_FIND_PATH $LOCAL_BACKUP_WWW_DIR/*.tgz -mtime +$COMMON_KEEP_DAYS -exec rm {} +

echo "Starting LFTP mirror..."
lftp -e "mirror -c -e -R $LOCAL_BACKUP_SITE_DIR $LFTP_BACKUP_SITE_DIR; bye;" -u $LFTP_USER,$LFTP_PASS ftp://$LFTP_SERVER