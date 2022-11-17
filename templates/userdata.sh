#!/bin/bash

# apt -y update && apt -y install awscli curl wget vim mc

cd /root
curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
chmod +x openvpn-install.sh
export AUTO_INSTALL=y
export DNS=2
export ENDPOINT=${instance_dns_name}.${dns_zone}
./openvpn-install.sh

# Check if OVPN configuration is present in the backet
# Download and unpack OVPN config if present
RELAY_BUCKET=${project}-relay-bucket
ARCHIVE_NAME=${project}-ovpn-config.tgz
BACKUP_DIR=/etc/openvpn

if [ $(aws s3 ls $RELAY_BUCKET | grep $ARCHIVE_NAME) ]; then 
    aws s3 cp s3://$RELAY_BUCKET/$ARCHIVE_NAME /tmp/
    rm -rf $BACKUP_DIR/*
    tar -P --preserve-permissions --same-owner -zxf /tmp/$ARCHIVE_NAME
    rm /tmp/$ARCHIVE_NAME
fi

# Small script to backup OVPN config
cat > /etc/cron.${bkp_freq}/ovpn_config_backup << EOF
#!/bin/sh
#
# Backup ovpn config dir hourly

tar -P -czf /tmp/$ARCHIVE_NAME $BACKUP_DIR
aws s3 mv /tmp/$ARCHIVE_NAME s3://$RELAY_BUCKET
EOF

# Make cron script executable
chmod 0774 /etc/cron.${bkp_freq}/ovpn_config_backup
