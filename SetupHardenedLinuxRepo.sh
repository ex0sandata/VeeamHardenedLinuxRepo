#!/bin/bash
  
#### als sudo oder root ausführen ####
set -e
if [[ $EUID -ne 0 ]]; then
    sudo "$0"
    exit $?
fi


#### Start:
source /var/scripts/lib.sh

install_if_not whiptail
install_if_not ssh
enable_service ssh

print_text_in_color "$BIPurple" "Generiere locale für aktuelle Session...."
install_if_not locales
locale-gen en_US.UTF-8
sleep 2
export LANG=C.UTF-8

run_script instructions

SCRIPT_NAME="Veeam Hardened Linux Repository Installation Skript"
SCRIPT_EXPLAINER="Dieses Skript installiert auf diesem Server ein Veeam Hardened Linux Repository."

msg_box "$SCRIPT_EXPLAINER"

print_text_in_color "$BIPurple" "Checke Hardware Requirements"
cpu_check 2 Veeam
ram_check 4 Veeam
check_distro_version

is_process_running apt
is_process_running dpkg

print_text_in_color "$BIPurple" "OS Patchen, bevor irgendetwas gemacht wird...."
update_system

print_text_in_color "$BIPurple" "Installiere dependencies...."
install_if_not lshw
install_if_not net-tools
install_if_not whiptail
install_if_not ufw
install_if_not ssh
install_if_not sudo
install_if_not netplan.io

## nice to have dependencies

print_text_in_color "$BIPurple" "Installiere nice-to-have dependencies...."
install_if_not htop
install_if_not btop
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
"1 Festplatte" "(Backups werden auf dieser Platte gemacht auf $BACKUPDIR (KEIN XFS!!))" 3>&1 1>&2 2>&3)

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

        if isPathMounted "$BACKUPDIR";      #Spaces in path names are ok.
        then
            msg_box "$BACKUPDIR ist im Moment gemountet und muss unmountet werden, um dieses Skript auszuführen."
            exit 1
        fi
        # Universal:
        if isMounted "$BACKUPDIR";
        then
            msg_box "$BACKUPDIR ist im Moment gemountet und muss unmountet werden, um dieses Skript auszuführen."
            exit 1
        fi

        # Verzeichnis anlegen:
        CreateBackupDir


    ;;
    *)
    ;;
esac


#### User anlegen: ####

run_script AddUser

#### Statische IP-Adresse anlegen: ####

if yesno_box_yes "Soll eine andere IP-Adresse für diesen Server konfiguriert werden?"
then
    run_script static_ip
fi

#### Server Hardening Options: ####

if yesno_box_yes "Soll ein Hardening für diesen Server durchgeführt werden? Wenn Sie mit 'yes' bestätigen, können Sie zwischen verschiedenen Optionen wählen."
then
    run_script hardening
else
    echo -e "Der SSH-Port für den Server ist: $SSHPORT" >> $CONFIG
fi

#### Veeam B&R Einrichtung Konsole ####

function brsetup (){
    msg_box "Die Konfiguration ist nun fertig. Bitte geben Sie nun die Daten folgenden Seiten in der Veeam Konsole ein, um diesen Server zu verbinden."

    msg_box "Die Konfigurationsdaten sind in dieser Datei gespeichert: $CONFIG
    Eine Anleitung mit Bildern zur Einrichtung in der Konsole finden Sie hier:
    ### LINK ###
    "
    msg_box "Letzter Hinweis: Sobald sie die den Server erfolgreich verbunden haben, wird das Root-Konto aus Sicherheitsgründen wieder deaktiviert.
    Falls das Root-Konto doch entsperrt werden sollte, führen Sie bitte diesen Command aus: 
    'sudo unlock-root'"

#-->    msg_box "$VEEAMUSERNAME $VEEAMPASSWD $VEEAMPORT $ROOTUSERNAME $ROOTPASSWD"

    if [ ! -f /usr/bin/unlock-root ]
    then
        echo -e "#/bin/bash\n passwd -u root \n source /var/scripts/lib.sh\n disableroot" >> /usr/bin/unlock-root && chmod +x /usr/bin/unlock-root
    fi
}

function readcreds (){
    brsetup
    while :
    do 
        if yesno_box_no "War die Einrichtung erfolgreich? Wenn Sie mit 'nein' bestätigen, werden die Credentials noch einmal angezeigt."
        then
            brsetup
        else
            passwd -l root
            enableroot
            break
        fi
    done
      
}
readcreds

#### Request Reboot: ####
if [ $REQUEST = 1 ]
then
    msg_box "Dieser Server wird jetzt neu gestartet, um den Mountpoint in /etc/fstab zu schreiben.
Sobald der Neustart erfolgt ist, ist der Server fertig eingerichtet"
fi

exit
