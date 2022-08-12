#!/bin/bash


#### Einige Teile dieses Scripts stammen von hier: https://github.com/nextcloud/vm/blob/master/nextcloud_install_production.sh/ ####

true
SCRIPT_NAME="Festplatte Formatieren"
MOUNT_="/opt/backups"
# shellcheck source=lib.sh
source /var/scripts/fetch_lib.sh

# Check if root
root_check

# Needed for partprobe
install_if_not parted

format() {
# umount if mounted
umount /mnt/* &> /dev/null

# mkdir if not existing
mkdir -p "$MOUNT_"

msg_box "Sie werden nun eine Liste von Geräten sehen, auf welchen das Backupverzeichnis angelegt werden soll:
Achtung! Alle Daten auf dieser Platte werden gelöscht werden!"
AVAILABLEDEVICES="$(lsblk | grep 'disk' | awk '{print $1}')"
# https://github.com/koalaman/shellcheck/wiki/SC2206
mapfile -t AVAILABLEDEVICES <<< "$AVAILABLEDEVICES"

# Ask for user input
while
    lsblk
    read -r -e -p "Enter the drive for the Nextcloud data:" -i "$DEVTYPE" userinput
    userinput=$(echo "$userinput" | awk '{print $1}')
        for disk in "${AVAILABLEDEVICES[@]}";
        do
            [[ "$userinput" == "$disk" ]] && devtype_present=1 && DEVTYPE="$userinput"
        done
    [[ -z "${devtype_present+x}" ]]
do
    printf "${BRed}$DEVTYPE is not a valid disk. Please try again.${Color_Off}\n"
    :
done

# Get the name of the drive
DISKTYPE=$(fdisk -l | grep "$DEVTYPE" | awk '{print $2}' | cut -d ":" -f1 | head -1)
if [ "$DISKTYPE" != "/dev/$DEVTYPE" ]
then
    msg_box "Es scheint, als würde auf diesem Rechner kein 2. Datenträger (/dev/$DEVTYPE) existieren.
Dieses Skript setzt eine 2. Festplatte voraus.
Bitte fahren Sie diesen Server wieder herunter und installieren eine zusätzliche Festplatte."
    exit 1
fi


# Check still not mounted
#These functions return exit codes: 0 = found, 1 = not found
isMounted() { findmnt -rno SOURCE,TARGET "$1" >/dev/null;} #path or device
isDevMounted() { findmnt -rno SOURCE        "$1" >/dev/null;} #device only
isPathMounted() { findmnt -rno        TARGET "$1" >/dev/null;} #path   only

if isPathMounted "/opt/backups";      #Spaces in path names are ok.
then
    msg_box "/opt/backups ist im Moment gemountet und muss unmountet werden, um dieses Skript auszuführen."
    exit 1
fi

if isDevMounted "/dev/$DEVTYPE";
then
    msg_box "/dev/$DEVTYPE ist im Moment gemountet und muss unmountet werden, um dieses Skript auszuführen."
    exit 1
fi

# Universal:
if isMounted "/opt/backups";
then
    msg_box "/opt/backups ist im Moment gemountet und muss unmountet werden, um dieses Skript auszuführen."
    exit 1
fi

if isMounted "/dev/${DEVTYPE}1";
then
    msg_box "/dev/${DEVTYPE}1 ist im Moment gemountet und muss unmountet werden, um dieses Skript auszuführen."
    exit 1
fi


if lsblk -l -n | grep -v mmcblk | grep disk | awk '{ print $1 }' | tail -1 > /dev/null
then
    msg_box "Formattiere auf diesem System das Volumen: ($DISKTYPE) wenn Sie OK drücken.
*** WARNUNG: ALLE DATEN AUF DIESEM DATENTRÄGER WERDEN GELÖSCHT! ***"
    if zpool list | grep "$POOLNAME" > /dev/null
    then
        wipefs -a -f $DISKTYPE
    fi
    check_command wipefs -a -f /dev/"$DISKTYPE"
    sleep 0.5
    mkfs.xfs -b size=4096 -m crc=1,reflink=1 /dev/"$DISKTYPE" -f
    

else
    msg_box "It seems like /dev/$DEVTYPE does not exist.
This script requires that you mount a second drive to hold the data.
Please shutdown the server and mount a second drive, then start this script again.
If you want help you can buy support in our shop:
https://shop.hanssonit.se/product/premium-support-per-30-minutes/"
    countdown "Please press 'CTRL+C' to abort this script and shutdown the server with 'sudo poweroff'" "120"
    exit 1
fi
}

format


# Check if UUID is used
if zpool list -v | grep "$DEVTYPE"
then
    # Import disk by actual name
    check_command partprobe -s
    zpool export $POOLNAME
    zpool import -d /dev/disk/by-id $POOLNAME
fi

# Success!
if grep "$POOLNAME" /etc/mtab
then
    msg_box "$MOUNT_ mounted successfully as a ZFS volume.
Automatic scrubbing is done monthly via a cronjob that you can find here:
/etc/cron.d/zfsutils-linux
Automatic snapshots are taken with 'zfs-auto-snapshot'. You can list current snapshots with:
'sudo zfs list -t snapshot'.
Manpage is here:
http://manpages.ubuntu.com/manpages/focal/man8/zfs-auto-snapshot.8.html
CURRENT STATUS:
$(zpool status $POOLNAME)
$(zpool list)"
fi
