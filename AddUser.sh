#!/bin/bash
true
SCRIPT_NAME="Add Backup User"
# shellcheck source=lib.sh
source /var/scripts/lib.sh


### Change passwords
UNIXUSER=$(whoami)

msg_box "Veeam empfiehlt einen neuen User anzulegen, der keine sudo- Rechte besitzt.
Der aktuelle User ist: $UNIXUSER.
Dieses Skript erstellt einen neuen User, der auf das Backupverzeichnis zugreifen darf.
Der User wird keine anderen Rechte besitzen."

if yesno_box_yes "Sollen der User 'veeam' automatisch angelegt und konfiguriert werden? 
Der User 'root' bekommt aus Sicherheitsgründen ein Starkes Passwort, welches zur Ersteinrichtung eingegeben werden muss,
danach wird der Account 'root' aus Sicherheitsgründen deaktiviert."
then
    
    print_text_in_color "$IGreen" "User 'veeam' wird automatisch angelegt..."
    useradd veeam
    useradd -b $BACKUPDIR -d $BACKUPDIR -s /bin/bash "$veeam"
    
    print_text_in_color "$IGreen" "Neuer User mit dem Namen veeam angelegt"
    groupadd VeeamBR
    usermod -G VeeamBR veeam
    
    print_text_in_color "$IGreen" "Verzeichnis $BACKUPDIR auf 'veeam' berechtigt"
    chown -R veeam:VeeamBR $BACKUPDIR 
    chmod 770 $BACKUPDIR

    print_text_in_color "$IPurple" "Generiere Passwort...."
    #random password generator
    VEEAMPASSWD=$(openssl rand -base64 20)

    if echo "veeam:$VEEAMPASSWD" | sudo chpasswd
    then
        echo "Das Passwort für den User Veeam ist:          $VEEAMPASSWD" >> $CONFIG
        echo "Dieses Passwort muss in der Veeam Konsole für die 'Single-Use Credentials' eingegeben werden" >> $CONFIG
    fi
else

    if [[ $UNIXUSER != "veeam" ]]
    then

        print_text_in_color "$IGreen" "Neuer User 'veeam' wird erstellt..." 
        useradd veeam
        useradd -b $BACKUPDIR -d $BACKUPDIR -s /bin/bash "$veeam"
        
        print_text_in_color "$IGreen" "Neuer User mit dem Namen veeam angelegt"
        groupadd VeeamBR
        usermod -G VeeamBR veeam
        
        print_text_in_color "$IGreen" "Verzeichnis $BACKUPDIR auf 'veeam' berechtigt"
        chown -R veeam:VeeamBR $BACKUPDIR 
        chmod 770 $BACKUPDIR

        msg_box "Bitte wählen Sie ein starkes Passwort für den neuen User 'veeam'"
        while :
        do
            VEEAMPASSWD=$(input_box_flow "Bitte ein neues Passwort eingeben:")
            if [[ "$VEEAMPASSWD" == *" "* ]]
            then
                msg_box "Das Passwort darf keine Leerzeichen enthalten."
            else
                break
            fi
        done

        if echo "veeam:$VEEAMPASSWD" | sudo chpasswd
        then
            msg_box "Das Passwort für den User 'veeam' ist nun '$VEEAMPASSWD'. Dieses Passwort muss in der Veeam Konsole später eingegeben werden. \n Das Passwort ist ebenfalls in der Textdatei $CONFIG gespeichert."
            echo "Das Passwort für den User Veeam ist:      $VEEAMPASSWD" >> $CONFIG
            echo "Dieses Passwort muss in der Veeam Konsole für die 'Single-Use Credentials' eingegeben werden" >> $CONFIG
        fi      
    
    fi

fi

    if [ echo $(passwd -a -S | grep root | awk '{print $2}') != "P"  ]
    then
        passwd -u root
    fi

    print_text_in_color "$IPurple" "Generiere Passwort für root...."
    #random password generator
    ROOTPASSWD=$(openssl rand -base64 31)

    if echo "root:$ROOTPASSWD" | sudo chpasswd
    then
        echo "Das Passwort für den User Root ist:          $ROOTPASSWD" >> $CONFIG
        echo "Dieses Passwort muss in der Root Konsole für die 'Single-Use Credentials' des Root-Benutzers eingegeben werden" >> $CONFIG
    fi

exit 0
