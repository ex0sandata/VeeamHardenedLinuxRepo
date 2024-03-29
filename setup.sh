#!/bin/bash
#### Einige Teile dieses Scripts stammen von hier: https://github.com/nextcloud/vm/blob/master/nextcloud_install_production.sh/ ####

#### als sudo oder root ausführen ####
set -e
if [[ $EUID -ne 0 ]]; then
    sudo "$0"
    exit $?
fi

# IPv4 for apt bevorzugen:
echo 'Acquire::ForceIPv4 "true";' >> /etc/apt/apt.conf.d/99force-ipv4

# Installiere curl wenn nicht existent
if [ "$(dpkg-query -W -f='${Status}' "curl" 2>/dev/null | grep -c "ok installed")" = "1" ]
then
    echo "curl OK" 
else
    apt-get update -q4
    apt-get install curl -y
fi

rm -rf /var/scripts
mkdir /var/scripts

curl -s https://raw.githubusercontent.com/ex0sandata/VeeamHardenedLinuxRepo/main/lib.sh > /var/scripts/lib.sh 
curl -s https://raw.githubusercontent.com/ex0sandata/VeeamHardenedLinuxRepo/main/FormatDisk.sh > /var/scripts/FormatDisk.sh
curl -s https://raw.githubusercontent.com/ex0sandata/VeeamHardenedLinuxRepo/main/SetupHardenedLinuxRepo.sh > /var/scripts/SetupHardenedLinuxRepo.sh
curl -s https://raw.githubusercontent.com/ex0sandata/VeeamHardenedLinuxRepo/main/AddUser.sh > /var/scripts/AddUser.sh
curl -s https://raw.githubusercontent.com/ex0sandata/VeeamHardenedLinuxRepo/main/instructions.sh > /var/scripts/instructions.sh
curl -s https://raw.githubusercontent.com/ex0sandata/VeeamHardenedLinuxRepo/main/hardening.sh > /var/scripts/hardening.sh
curl -s https://raw.githubusercontent.com/ex0sandata/VeeamHardenedLinuxRepo/main/static_ip.sh > /var/scripts/static_ip.sh

chmod +x /var/scripts/*.sh
/bin/bash /var/scripts/SetupHardenedLinuxRepo.sh