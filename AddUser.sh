#!/bin/bash
true
SCRIPT_NAME="Add Backup User"
# shellcheck source=lib.sh
source /var/scripts/lib.sh

UNIXUSER=$(whoami)

if [[ $UNIXUSER != "veeam" ]]
then
    msg_box "Veeam empfiehlt einen neuen User anzulegen, der keine sudo- Rechte besitzt.
    Der aktuelle User ist: $UNIXUSER.
    Dieses Skript erstellt einen neuen User, der auf das Backupverzeichnis zugreifen darf.
    Der User darf keine sudo- Rechte haben!"
    if ! yesno_box_yes "Soll ein neuer User erstellt werden?"
    then
        print_text_in_color "$ICyan" "Not adding another user..."
        sleep 1
    else
        print_text_in_color "$IPurple" "Neuer User wird erstellt:"
        read -r -p "Namen des neuen Users eingeben: " NEWUSER
        useradd -b /opt/backups -d /home/backups -s /bin/bash "$NEWUSER"
        
        print_text_in_color "$IGreen" "Neuer User mit dem Namen $NEWUSER angelegt"
        groupadd VeeamBR
        usermod -G VeeamBR "$NEWUSER"
        while :
        do
            sudo passwd "$NEWUSER" && break
        done
        sudo -u "$NEWUSER" sudo bash "$1"

        print_text_in_color "$IGreen" "Verzeichnis /opt/backups auf $NEWUSER berechtigt"
        chown -R "$NEWUSER" /opt/backups 
        chmod 770 /opt/backups
    fi
fi
