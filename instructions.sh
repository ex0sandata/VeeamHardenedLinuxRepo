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
echo -e "|"  "${IGreen} Um dieses Skript zu starten, bitte geben sie das sudo- Passwort ein: [ENTER].${Color_Off} |"
# echo -e "|"  "${IGreen}: ${BIGreen}nextcloud${IGreen}${Color_Off}                             |"
cat << INST2
|                                                                       |
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

exit 0
