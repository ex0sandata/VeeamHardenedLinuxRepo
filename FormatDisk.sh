#!/bin/bash


#### Einige Teile dieses Scripts stammen von hier: https://github.com/nextcloud/vm/blob/master/nextcloud_install_production.sh/ ####

true
SCRIPT_NAME="Festplatte Formatieren"
MOUNT_="/opt/backups"
# shellcheck source=lib.sh
source /var/scripts/lib.sh

if [[ $EUID -ne 0 ]]; then
    set -e
    print_text_in_color "$IRed" "Skript nicht als sudo / root ausgeführt, bitte Passwort eingeben:"
    sudo "$0"
    exit $?
fi

# Needed for partprobe
install_if_not parted

format() {
# umount if mounted
umount /mnt/* &> /dev/null

# mkdir if not existing
mkdir -p "/opt/backups"

msg_box "Sie werden nun eine Liste von Geräten sehen, auf welchen das Backupverzeichnis angelegt werden soll:
Achtung! Alle Daten auf dieser Platte werden gelöscht werden!"
AVAILABLEDEVICES="$(lsblk | grep 'disk' | awk '{print $1}')"
# https://github.com/koalaman/shellcheck/wiki/SC2206
mapfile -t AVAILABLEDEVICES <<< "$AVAILABLEDEVICES"

# Ask for user input
while
    lsblk
    #lsblk | grep disk | awk '{print $1, $4}' | column -t | 
    read -r -e -p "Speicherort für Veeam-Backupdaten eingeben:" -i "$DEVTYPE" userinput
    userinput=$(echo "$userinput" | awk '{print $1}')
        for disk in "${AVAILABLEDEVICES[@]}";
        do
            [[ "$userinput" == "$disk" ]] && devtype_present=1 && DEVTYPE="$userinput"
        done
    [[ -z "${devtype_present+x}" ]]
do
    printf "${BRed}$DEVTYPE ist keine gültige Festplatte. Bitte erneut veruschen.${Color_Off}\n"
    :
done

# Get the name of the drive
DISKTYPE=$(fdisk -l | grep "$DEVTYPE" | awk '{print $2}' | cut -d ":" -f1 | head -1)
GREPC=$(lsblk | grep -c disk )
if [ "$DISKTYPE" != "/dev/$DEVTYPE" ]
then
    msg_box "Es scheint, als würde auf diesem Rechner kein 2. Datenträger (/dev/$DEVTYPE) existieren.
    Dieses Skript setzt eine 2. Festplatte voraus.
    Bitte fahren Sie diesen Server wieder herunter und installieren eine zusätzliche Festplatte."
    exit 1
elif [ "$GREPC" = 1 ]
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
    
    print_text_in_color "$Blue" "/dev/$DISKTYPE wird gelöscht..."
    wipefs -a -f /dev/"$DISKTYPE"
    sleep 0.5
    print_text_in_color "$IBlue" "/dev/$DISKTYPE wird mit XFS formattiert..."
    mkfs.xfs -b size=4096 -m crc=1,reflink=1 /dev/"$DISKTYPE" -f
    

else
    msg_box "Es scheint, als würde /dev/$DEVTYPE nicht existieren.
    Diese Option erfordert eine zusätzliche Festplatte.
    Bitte fahren Sie diesen Server herunter und installieren Sie eine weitere Festplatte."
    countdown "Please press 'CTRL+C' to abort this script and shutdown the server with 'sudo poweroff'" "120"
    exit 1
fi
}

format

print_text_in_color "$IGreen" "/dev/$DISKTYPE wurde erfolgreich eingerichtet!"

# Check if UUID is used
if zpool list -v | grep "$DEVTYPE"
then
    # Import disk by actual name
    check_command partprobe -s
fi

# Success!
if grep "$POOLNAME" /etc/mtab
then
    msg_box "$MOUNT_ mounted successfully as a ZFS volume.
CURRENT STATUS:
$(zpool status $POOLNAME)

fi
