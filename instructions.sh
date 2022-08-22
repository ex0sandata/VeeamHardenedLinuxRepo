#!/bin/bash

# Silas Suessmilch © - 2022

clear

#### Start:
source /var/scripts/lib.sh


  msg_box " Willkommen bei der Erstinstallation eines Veeam Hardened Linux Repositories! 
Optional:                                                           
Sie können den Server auch via SSH-Session einrichten. Windows unterstützt dieses Feature seit v.1809 nativ
auf Konsolen (cmd / PS). Sie können sich wie folgt verbinden: ssh $UNIXUSER@IP-Adresse"
    if yesno_box_yes "Fortfahren(y/n)?"
    then
        print_text_in_color "$IGreen" "Setup wird gestartet.."
        print_text_in_color "$IPurple" " ###################### Silas Suessmilch - SanData GmbH - $(date +"%Y") ######################"
    else
        print_text_in_color "$IRed" "Abbruch..."
        exit 1 && break
    fi

exit 0
