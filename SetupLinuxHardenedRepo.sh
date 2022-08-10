#!/bin/bash

#### Einige Teile dieses Scripts stammen von hier: https://github.com/nextcloud/vm/blob/master/nextcloud_install_production.sh/ ####
    
#### als sudo oder root ausfuehren ####
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

true
SCRIPT_NAME="Veeam Hardened Linux Repository Installation Skript"
SCRIPT_EXPLAINER="Dieses Skript installiert auf diesem Server ein Veeam Hardened Linux Repo."

# shellcheck source=lib.sh
#source <(curl -sL ###ÄNDERN###)
source ./lib.sh

cpu_check 2 Veeam
ram_check 4 Veeam

is_process_running apt
is_process_running dpkg

# Automatically restart services
# Restart mode: (l)ist only, (i)nteractive or (a)utomatically.
sed -i "s|#\$nrconf{restart} = .*|\$nrconf{restart} = 'a';|g" /etc/needrestart/needrestart.conf

install_if_not lshw
install_if_not net-tools
install_if_not whiptail
install_if_not apt-utils
install_if_not apt-ufw
install_if_not sshd
install_if_not sudo
install_if_not apt-transport-https
install_if_not netplan.io

## nice to have dependencies

install_if_not htop
install_if_not dnsutils

# We don't want automatic updates since they might fail (we use our own script)
if is_this_installed unattended-upgrades
then
    apt-get purge unattended-upgrades -y
    apt-get autoremove -y
    rm -rf /var/log/unattended-upgrades
fi

#### Festplatten config #### 

    msg_box "Dieser Server ist dafür designt, mit 2 Hard Disks zu laufen eine für das OS eine für Daten. \
Dadurch wird das System Performanter, da auf der zweiten Festplatte XFS (überlegenes FileSystem) läuft.\
Obwohl es nicht empfohlen ist, kann dieses System auch nur auf einer Festplatte laufen, der Mountpoint für Backups ist /opt/ . \
Bei der Option mit einer Festplatte, kann kein XFS verwendet werden!!
"

    choice=$(whiptail --title "$TITLE - Festplattenformatierung" --nocancel --menu \
"Wie sollen die Festplatten formattiert werden?
$MENU_GUIDE" "$WT_HEIGHT" "$WT_WIDTH" 4 \
"2 Festplatten" "(Wird automatisch konfiguriert)" \
"1 Festplatte" "(Backups werden auf dieser Platte gemacht auf /opt/backups (KEIN XFS!!))" 3>&1 1>&2 2>&3)
fi

case "$choice" in
    "2 Festplatten")
        run_script DISK format-sdb
        # Change to zfs-mount-generator
        run_script DISK change-to-zfs-mount-generator
        # Create daily zfs prune script
        run_script DISK create-daily-zfs-prune

    ;;
    "1 Festplatte")
        print_text_in_color "$IRed" "1 Disk setup chosen."
        sleep 2
    ;;
    *)
    ;;
esac


#### User anlegen: ####

#### Festplatte für Repo und xfs: ####
#mkfs.xfs -b size=4096 -m crc=1,reflink=1 /dev/sdb -f



exit
