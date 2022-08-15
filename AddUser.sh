#!/bin/bash
true
SCRIPT_NAME="Add Backup User"
# shellcheck source=lib.sh
source /var/scripts/lib.sh


### Change passwords
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
        useradd veeam
        useradd -b /opt/backups -d /home/backups -s /bin/bash "$veeam"
        
        print_text_in_color "$IGreen" "Neuer User mit dem Namen veeam angelegt"
        groupadd VeeamBR
        usermod -G VeeamBR veeam
        
        print_text_in_color "$IGreen" "Verzeichnis /opt/backups auf 'veeam' berechtigt"
        chown -R veeam:VeeamBR /opt/backups 
        chmod 770 /opt/backups

        msg_box "Bitte wählen Sie ein starkes Passwort für den neuen User 'veeam'"
        while :
        do
            UNIX_PASSWORD=$(input_box_flow "Bitte ein neues Passwort eingeben:")
            if [[ "$UNIX_PASSWORD" == *" "* ]]
            then
                msg_box "Bitte keine Leerzeichen benutzen."
            else
                break
            fi
        done

        if echo "veeam:$UNIX_PASSWORD" | sudo chpasswd
        then
            msg_box "Das Passwort für den User 'veeam' ist nun '$UNIX_PASSWORD'. Dieses Passwort muss in der Veeam Konsole später eingegeben werden."
        fi      

    fi
fi


msg_box "Für die einmalige Einrichtung dieses Servers in der Veeam Konsole muss das Root Passwort festgelegt werden.
Dieses MUSS ein starkes Passwort sein!"
    while :
    do
        ROOT_PASSWORD=$(input_box_flow "Bitte ein neues Passwort eingeben:")
        if [[ "$ROOT_PASSWORD" == *" "* ]]
        then
            msg_box "Bitte keine Leerzeichen benutzen."
        else
            break
        fi

        ROOT_PASSWORD=$(input_box_flow "Bitte ein neues Passwort eingeben:")
        if [[ $(expr length "$ROOT_PASSWORD" -lt 15 ]]
        then
            msg_box "Das Passwort muss mindestens 15 Zeichen besitzen."
        else
            break
        fi
    done
    
    if echo "root:$ROOT_PASSWORD" | sudo chpasswd
    then
        msg_box "Das Passwort für den User 'root' ist nun '$ROOT_PASSWORD'. Dieses Passwort muss in der Veeam Konsole später eingegeben werden."
    fi

msg_box "Dieser Server ist nun fertig eingerichtet. Bitte notieren Sie folgende Daten, die Sie in der Veeam Konsole 
eingeben müssen, um den Server zu verbinden: \


Eine Anleitung mit Bildern zur Einrichtung in der Konsole 
"
