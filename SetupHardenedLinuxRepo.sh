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

# shellcheck source=lib.sh
if [ ! -d /var/scripts ]
then
    mkdir /var/scripts
fi

rm -rf /var/scripts
mkdir /var/scripts

curl https://raw.githubusercontent.com/ex0sandata/VeeamHardenedLinuxRepo/main/lib.sh -s > /var/scripts/lib.sh 
curl https://raw.githubusercontent.com/ex0sandata/VeeamHardenedLinuxRepo/main/FormatDisk.sh -s > /var/scripts/FormatDisk.sh
curl https://raw.githubusercontent.com/ex0sandata/VeeamHardenedLinuxRepo/main/SetupHardenedLinuxRepo.sh -s > /var/scripts/SetupHardenedLinuxRepo.sh
curl https://raw.githubusercontent.com/ex0sandata/VeeamHardenedLinuxRepo/main/AddUser.sh -s > /var/scripts/AddUser.sh
curl https://raw.githubusercontent.com/ex0sandata/VeeamHardenedLinuxRepo/main/instructions.sh -s > /var/scripts/instructions.sh

chmod +x /var/scripts/*.sh


#### Start:
source /var/scripts/lib.sh

run_script instructions

true
SCRIPT_NAME="Veeam Hardened Linux Repository Installation Skript"
SCRIPT_EXPLAINER="Dieses Skript installiert auf diesem Server ein Veeam Hardened Linux Repository."
   

print_text_in_color "$BIPurple" "Generiere locale für aktuelle session...."
install_if_not locales
locale-gen en_US.UTF-8
sleep 2
export LANG=C.UTF-8

msg_box "$SCRIPT_EXPLAINER"

cpu_check 2 Veeam
ram_check 4 Veeam
check_distro_version

is_process_running apt
is_process_running dpkg

print_text_in_color "$BIPurple" "OS Patchen, bevor irgendetwas gemacht wird...."
update_system

# Automatically restart services
# Restart mode: (l)ist only, (i)nteractive or (a)utomatically.
#sed -i "s|#\$nrconf{restart} = .*|\$nrconf{restart} = 'a';|g" /etc/needrestart/needrestart.conf

print_text_in_color "$BIPurple" "Installiere dependencies...."
install_if_not lshw
install_if_not net-tools
install_if_not whiptail
install_if_not apt-utils
install_if_not ufw
install_if_not ssh
install_if_not sudo
install_if_not apt-transport-https
install_if_not netplan.io

## nice to have dependencies

print_text_in_color "$BIPurple" "Installiere nice-to-have dependencies...."
install_if_not htop
install_if_not dnsutils

# We don't want automatic updates since they might fail (we use our own script)
print_text_in_color "$BIPurple" "deaktiviere automatische Updates...."
if is_this_installed unattended-upgrades
then
    apt-get purge unattended-upgrades -y
    apt-get autoremove -y
    rm -rf /var/log/unattended-upgrades
fi

#### Festplatten config #### 

    msg_box "Dieser Server ist dafür designt, mit 2 Hard Disks zu laufen, eine für das OS eine für Daten. \
Dadurch wird das System performanter, da auf der zweiten Festplatte XFS (überlegenes FileSystem) läuft. \
Obwohl es nicht empfohlen wird, kann dieses System auch nur auf einer Festplatte laufen, der Mountpoint für Backups ist  dann /opt/ . \
Bei dieser Option mit einer Festplatte kann kein XFS verwendet werden!!
"

    choice=$(whiptail --title "$TITLE - Festplattenformatierung" --nocancel --menu \
"Wie sollen die Festplatten formattiert werden?
$MENU_GUIDE" "$WT_HEIGHT" "$WT_WIDTH" 4 \
"2 Festplatten" "(Wird automatisch konfiguriert)" \
"1 Festplatte" "(Backups werden auf dieser Platte gemacht auf /opt/backups (KEIN XFS!!))" 3>&1 1>&2 2>&3)

case "$choice" in
    "2 Festplatten")
        # ausgewählte Festplatte formattieren
        print_text_in_color "$IPurple" "Setup mit 2 Festplatten ausgewählt."
        run_script FormatDisk
        # 

    ;;
    "1 Festplatte")
        print_text_in_color "$IPurple" "Setup mit 1 Festplatte ausgewählt."
        sleep 2

        isMounted() { findmnt -rno SOURCE,TARGET "$1" >/dev/null;} #path or device
        isPathMounted() { findmnt -rno        TARGET "$1" >/dev/null;} #path only

        if isPathMounted "/opt/backups";      #Spaces in path names are ok.
        then
            msg_box "/opt/backups ist im Moment gemountet und muss unmountet werden, um dieses Skript auszuführen."
            exit 1
        fi
        # Universal:
        if isMounted "/opt/backups";
        then
            msg_box "/opt/backups ist im Moment gemountet und muss unmountet werden, um dieses Skript auszuführen."
            exit 1
        fi

        # Verzeichnis anlegen:
        mkdir -p "/opt/backups"

        print_text_in_color "$IGreen" "Directory /opt/backups erfolgreich angelegt."

    ;;
    *)
    ;;
esac


#### User anlegen: ####
run_script AddUser


exit
