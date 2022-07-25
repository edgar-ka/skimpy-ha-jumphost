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

# Create cron job to save config to the backet hourly