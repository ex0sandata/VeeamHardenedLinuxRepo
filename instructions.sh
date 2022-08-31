#!/bin/bash

# Silas Suessmilch © - 2022

clear

#### Start:
source /var/scripts/lib.sh
UNIXUSER=$(whoami)
ADDRESS=$(hostname -I | cut -d ' ' -f 1)

msg_box "Willkommen bei der Erstinstallation eines Veeam Hardened Linux Repositories! 

Optional:                                                           
Sie können den Server auch via SSH-Session einrichten. Windows unterstützt dieses Feature seit v.1809 nativ
auf Konsolen (cmd / PS). Sie können sich wie folgt verbinden: ssh $UNIXUSER@$ADDRESS"
    if yesno_box_yes "Möchten Sie mit der Einrichtung fortfahren(y/n)?"
    then
        print_text_in_color "$IGreen" "Setup wird gestartet.."
        msg_box "Alle eigenen Konfigurationen, wie Benutzernamen und Passwörter werden nach der Einrichtung des Veeam Hardened Linux Repositories in der Textdatei $CONFIG gespeichert. Diese Credentials sind für die Einrichtung in der Veeam Konsole wichtig."
        print_text_in_color "$IPurple" " ###################### Silas Suessmilch - SanData GmbH - $(date +"%Y") ######################"
    
        if [ -f $CONFIG ]
        then
            rm -f $CONFIG
        fi
        touch $CONFIG
        echo -e "###### In dieser Textdatei stehen alle vorgenommenen Konfigurationen für das Veeam Hardened Linux Repository ###### \n" >> $CONFIG

    else
        print_text_in_color "$IRed" "Abbruch..."
        exit 1 && break
    fi

exit 0
