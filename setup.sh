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

# Fix fancy progress bar for apt-get
# https://askubuntu.com/a/754653
if [ -d /etc/apt/apt.conf.d ]
then
    if ! [ -f /etc/apt/apt.conf.d/99progressbar ]
    then
        echo 'Dpkg::Progress-Fancy "1";' > /etc/apt/apt.conf.d/99progressbar
        echo 'APT::Color "1";' >> /etc/apt/apt.conf.d/99progressbar
        chmod 644 /etc/apt/apt.conf.d/99progressbar
    fi
fi


# Installiere curl wenn nicht existent
if [ "$(dpkg-query -W -f='${Status}' "curl" 2>/dev/null | grep -c "ok installed")" = "1" ]
then
    echo "curl OK"
else
    apt-get update -q4
    apt-get install curl -y
fi

# Installiere Screen wenn nicht existent
if [ "$(dpkg-query -W -f='${Status}' "screen" 2>/dev/null | grep -c "ok installed")" = "1" ]
then
    echo "screen OK"
else
    apt-get update -q4
    apt-get install screen -y
fi

rm -rf /var/scripts
mkdir /var/scripts

curl https://raw.githubusercontent.com/ex0sandata/VeeamHardenedLinuxRepo/main/lib.sh -s > /var/scripts/lib.sh 
curl https://raw.githubusercontent.com/ex0sandata/VeeamHardenedLinuxRepo/main/FormatDisk.sh -s > /var/scripts/FormatDisk.sh
curl https://raw.githubusercontent.com/ex0sandata/VeeamHardenedLinuxRepo/main/SetupHardenedLinuxRepo.sh -s > /var/scripts/SetupHardenedLinuxRepo.sh
curl https://raw.githubusercontent.com/ex0sandata/VeeamHardenedLinuxRepo/main/AddUser.sh -s > /var/scripts/AddUser.sh
curl https://raw.githubusercontent.com/ex0sandata/VeeamHardenedLinuxRepo/main/instructions.sh -s > /var/scripts/instructions.sh
curl https://raw.githubusercontent.com/ex0sandata/VeeamHardenedLinuxRepo/main/hardening.sh -s > /var/scripts/hardening.sh
curl https://raw.githubusercontent.com/ex0sandata/VeeamHardenedLinuxRepo/main/static_ip.sh -s > /var/scripts/static_ip.sh

chmod +x /var/scripts/*.sh

#### Start:
/bin/screen -mS VHLR /bin/bash /var/scripts/SetupHardenedLinuxRepo.sh

#/bin/bash /var/scripts/SetupHardenedLinuxRepo.sh
