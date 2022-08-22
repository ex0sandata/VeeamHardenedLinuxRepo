#!/bin/bash

# Silas Suessmilch © - 2022

clear

#### Start:
source /var/scripts/lib.sh
UNIXUSER=$(whoami)

msg_box "Willkommen bei der Erstinstallation eines Veeam Hardened Linux Repositories! 

Optional:                                                           
Sie können den Server auch via SSH-Session einrichten. Windows unterstützt dieses Feature seit v.1809 nativ
auf Konsolen (cmd / PS). Sie können sich wie folgt verbinden: ssh $UNIXUSER@IP-Adresse"
    if yesno_box_yes "Möchten Sie mit der Einrichtung fortfahren(y/n)?"
    then
        print_text_in_color "$IGreen" "Setup wird gestartet.."
        msg_box "Alle eigenen Konfigurationen, wie Benutzernamen und Passwörter werden nach der Einrichtung des Veeam Hardened Linux Repositories in der Textdatei
        /root/VHLR.txt gespeichert. Diese Credentials sind für die Einrichtung in der Veeam Konsole wichtig."
        print_text_in_color "$IPurple" " ###################### Silas Suessmilch - SanData GmbH - $(date +"%Y") ######################"
    else
        print_text_in_color "$IRed" "Abbruch..."
        exit 1 && break
    fi

exit 0
