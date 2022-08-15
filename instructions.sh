#!/bin/bash

# Silas Suessmilch © - 2022

BIGreen='\e[1;92m'      # Green
IGreen='\e[0;92m'       # Green
Color_Off='\e[0m'       # Text Reset

clear
cat << INST1
+-----------------------------------------------------------------------+
|              Willkommen bei der Erstinstallation eines                |
|                 Veeam Hardened Linux Repositories!                    |
|                                                                       |
INST1
echo "|                                                                       |"
echo "|                    Um mit der Einrichtung zu starten,                 |"
echo "|                  bestätigen Sie bitte die Eingabe mit y/n.            |"
read -p "Fortfahren(y/n)?" CONT
if [ "$CONT" = "y" ]; then
    cat << INST2
    |                                                                       |
    | Optional:                                                             |
    | Sie können den Server auch via SSH-Session einrichten. Windows        |
    | unterstützt dieses Feature seit v.1809 nativ auf Konsolen (cmd / PS)  |
    | Sie können sich wie folgt verbinden: ssh $UNIXUSER@IP-Adresse         |
    |                                                                       |
    |                                                                       |
    |  ###################### Silas Suessmilch - SanData GmbH - $(date +"%Y") ######################  |
    +-----------------------------------------------------------------------+
INST2
else
    exit 0
fi




exit 0
