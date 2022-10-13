#!/bin/bash

SSHPORT=22
source /var/scripts/lib.sh

function SSHPort(){

        # Check if webmin is already installed
    SSHPORT=28910
    cat << SSH_CONF > "$SSH_CONF"

    AllowTcpForwarding no
    ClientAliveCountMax 2
    Compression no
    LogLevel verbose
    MaxAuthTries 2
    MaxSessions 2
    PermitRootLogin no
    # Port will be changed
    Port 28910
    # See https://de.wikipedia.org/wiki/Liste_der_standardisierten_Ports
    TCPKeepAlive no
    X11Forwarding no
    AllowAgentForwarding no
    # https://help.ubuntu.com/community/SSH/OpenSSH/Configuring#Specify_Which_Accounts_Can_Use_SSH
    AllowUsers $REALUSER
SSH_CONF

    # Inform user
    msg_box "SSH ist erfolgreich gehärtet worden!"

}

function fail2ban(){
    SCRIPT_NAME="Fail2Ban"
    SCRIPT_EXPLAINER="Fail2ban provides extra Brute Force protextion for Nextcloud.
    It scans the Nextcloud and SSH log files and bans IPs that show malicious \
    signs -- too many password failures, seeking for exploits, etc. 
    Generally Fail2Ban is then used to update firewall rules to \
    reject the IP addresses for a specified amount of time."

    # Check if fail2ban is already installed
    if ! [ -f /etc/fail2ban/filter.d/veeam.conf ] || ! is_this_installed fail2ban
    then
        # Ask for installing
        install_popup "$SCRIPT_NAME"
    else
        # Ask for removal or reinstallation
        reinstall_remove_menu "$SCRIPT_NAME"
        # Removal

        print_text_in_color "$ICyan" "Unbanning all currently blocked IPs..."
        fail2ban-client unban --all
        apt-get purge fail2ban -y
        rm -rf /etc/fail2ban
        crontab -u root -l | grep -v "$SCRIPTS/daily_fail2ban_report.sh"  | crontab -u root -
        rm -rf "$SCRIPTS/daily_fail2ban_report.sh"

    fi

    # Check if the DIR actually is a file
    if [ -f /var/log/fail2ban ]
    then
        rm -f /var/log/fail2ban
    fi


    # Install iptables
    install_if_not iptables

    # time to ban an IP that exceeded attempts
    BANTIME_=1209600
    # cooldown time for incorrect passwords
    FINDTIME_=1800
    # failed attempts before banning an IP
    MAXRETRY_=20

    apt-get update -q4 & spinner_loading
    install_if_not fail2ban -y
    update-rc.d fail2ban disable

    # Create veeam.conf file
    # Using https://docs.nextcloud.com/server/stable/admin_manual/installation/harden_server.html#setup-a-filter-and-a-jail-for-nextcloud
    cat << NCONF > /etc/fail2ban/filter.d/veeam.conf
    [Definition]
    _groupsre = (?:(?:,?\s*"\w+":(?:"[^"]+"|\w+))*)
    failregex = ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Login failed:
                ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Trusted domain error.
    datepattern = ,?\s*"time"\s*:\s*"%%Y-%%m-%%d[T ]%%H:%%M:%%S(%%z)?"
NCONF


    # Create jail.local file
    cat << FCONF > /etc/fail2ban/jail.local
    # The DEFAULT allows a global definition of the options. They can be overridden
    # in each jail afterwards.
    [DEFAULT]
    # "ignoreip" can be an IP address, a CIDR mask or a DNS host. Fail2ban will not
    # ban a host which matches an address in this list. Several addresses can be
    # defined using space separator.
    ignoreip = 127.0.0.1/8 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8
    # "bantime" is the number of seconds that a host is banned.
    bantime  = $BANTIME_
    # A host is banned if it has generated "maxretry" during the last "findtime"
    # seconds.
    findtime = $FINDTIME_
    maxretry = $MAXRETRY_
    #
    # ACTIONS
    #
    banaction = iptables-multiport
    protocol = tcp
    chain = INPUT
    action_ = %(banaction)s[name=%(__name__)s, port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
    action_mw = %(banaction)s[name=%(__name__)s, port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
    action_mwl = %(banaction)s[name=%(__name__)s, port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
    action = %(action_)s
    #
    # SSH
    #
    [sshd]
    enabled  = true
    maxretry = $MAXRETRY_
    #
    # HTTP servers
    #
    [veeam]
    enabled  = true
    port     = http,https
    filter   = veeam
    logpath  = /var/log/fail2ban_veeam.log
    maxretry = $MAXRETRY_
FCONF

    # Update settings
    check_command update-rc.d fail2ban defaults
    check_command update-rc.d fail2ban enable
    check_command systemctl restart fail2ban.service

    # The End
    msg_box "Fail2ban is now successfully installed.
    Please use 'fail2ban-client set veeam unbanip <Banned IP>' to unban certain IPs
    You can also use 'iptables -L -n' to check which IPs that are banned"

    # Daily ban notification
    if ! yesno_box_no "Do you want to get notified about daily bans?\n
    If you choose 'yes', you will receive a notification about daily bans at 23:59h."
    then
    exit
    fi

    # Create Fail2ban report script
    cat << FAIL2BAN_REPORT > "$SCRIPTS/daily_fail2ban_report.sh"
    #!/bin/bash

    # Look for ip addresses
    BANNED_IPS=\$(grep "Ban " /var/log/fail2ban.log | grep "\$(date +%Y-%m-%d)" \
    | awk -F "NOTICE  " '{print "Jail:",\$2}' | sort)
    # Exit if nothing was found
    if [ -z "\$BANNED_IPS" ]
    then
        exit
    fi
    # Report if something was found
    source /var/scripts/lib.sh
    send_mail "Your daily Fail2Ban report" "These IP's got banned today:
    \$BANNED_IPS"

FAIL2BAN_REPORT

    # Add crontab entry
    crontab -u root -l | grep -v "$SCRIPTS/daily_fail2ban_report.sh"  | crontab -u root -
    crontab -u root -l | { cat; echo "59 23 * * * $SCRIPTS/daily_fail2ban_report.sh > /dev/null"; } | crontab -u root -

    # Adjust access rights
    chown root:root "$SCRIPTS/daily_fail2ban_report.sh"
    chmod 700 "$SCRIPTS/daily_fail2ban_report.sh"

    # Inform user
    msg_box "The daily Fail2Ban report was successfully configured.\n
    You will get notified at 23:59h if new bans were made that day."

    exit
}

function GAuth(){
    # Allow to enable 2FA for SSH
    if ! yesno_box_no "Wollen Sie 2-Faktor Authentifizierung für SSH aktivieren?
    (Sie benötigen dafür ein Smartphone, \
    welches einen Passwortgenerator (OTP) wie Google Authenticator besitzt.)"
    then
        exit
    fi

    # https://ubuntu.com/tutorials/configure-ssh-2fa#2-installing-and-configuring-required-packages
    print_text_in_color "$ICyan" "2-Faktor Authentifizierung für SSH wird aktiviert..."
    install_if_not libpam-google-authenticator

    # Edit /etc/pam.d/sshd
    if ! grep -q '^auth required pam_google_authenticator.so' /etc/pam.d/sshd
    then
        echo "auth required pam_google_authenticator.so" >> /etc/pam.d/sshd
    fi

    # ChallengeResponseAuthentication no in /etc/ssh/sshd_config verändern
    if grep -q '^ChallengeResponseAuthentication' /etc/ssh/sshd_config
    then
        sed -i 's|^ChallengeResponseAuthentication.*|ChallengeResponseAuthentication yes|' /etc/ssh/sshd_config
    else
        echo 'ChallengeResponseAuthentication yes' >> /etc/ssh/sshd_config
    fi


    # Create OTP code
    if sudo -u "$REALUSER" \
        google-authenticator \
        --time-based \
        --disallow-reuse \
        --rate-limit=3 \
        --rate-time=30 \
        --step-size=30 \
        --force \
        --window-size=3
    then
        msg_box "Bitte stellen Sie sicher, dass Sie den QR-Code mit der OTP-App scannen und die Notfall-Codes aufschreiben!\n
    Ohne diese können Sie sich nicht mehr via SSH einloggen!
    Um 2FA zu deaktiveren, müssen Sie dieses Skript erneut starten (sudo bash /var/scripts/hardening.sh)."
        any_key "Eine Taste Drücken, um weiterzumachen"
        while :
        do 
            if ! yesno_box_no "Sind Sie sicher, dass Sie den QR-Code gescannt haben und die Notfall-Codes notiert haben?\n
    Ohne diese können Sie sich nicht mehr via SSH einloggen!
    Um 2FA zu deaktiveren, müssen Sie dieses Skript erneut starten (sudo bash /var/scripts/hardening.sh)."
            then
                any_key "Eine Taste Drücken, um weiterzumachen"
            else
                break
            fi
        done
        msg_box "2FA SSH authentication für $REALUSER wurde erfolgreich konfiguriert.\n
    Die Backup-Codes sind in: /root/.google_authenticator
    Um 2FA zu deaktiveren, müssen Sie dieses Skript erneut starten (sudo bash /var/scripts/hardening.sh)."
    else
        msg_box "2FA SSH authentication Konfiguration war nicht erfolgreich.\n
    Um 2FA zu deaktiveren, müssen Sie dieses Skript erneut starten (sudo bash /var/scripts/hardening.sh)!\n
    Ansonsten können Sie sich nicht mehr via SSH einloggen."
    fi
}

function PrivKey(){
    continue
}

function Advantage(){
    continue
}

# Show a msg_box during the startup script
if [ -f "$SCRIPTS/nextcloud-startup-script.sh" ]
then
    msg_box "Im nächsten Schritt werden Ihnen unterschiedliche Möglichkeiten geboten, Ihr System zu härten. Allerdings können bei der gleichzeitigen
Verwendung von einigen Funktionen Leistungs- und Kompatibilitätseinschränkungen auftreten. Deswegen sollte *nicht* alles gleichzeitig angewählt werden.

Alle vorgenommenen Einstellungen können durch das wiederholte Ausführen dieses Skripts wieder rückgängig gemacht werden. Dafür bitte 'sudo bash /var/scripts/hardening.sh' ausführen."
fi

# Server configurations
choice=$(whiptail --title "$TITLE" --checklist \
"Bitte wählen Sie aus, was konfiguriert werden soll:"
"Ändern des SSH Ports" "(Verschleierung des Servers)" OFF \
"Ubuntu Advantage" "Viele Ubuntu ESM funktionen, z.B. Kernel-LivePatch" OFF \
"Installation von Fail2Ban" "(Bei zu viel Fehlerhaften SSH-Login Versuchen wird der Service deaktiviert)" OFF \
"SSH PrivateKey Authentifizierung" "(Verwenden eines Private Key zum einloggen von SSH-Sessions)" OFF \
"Multi-Faktor Authentifizierung" "(Verwendung von Google Authenticator)" OFF )

case "$choice" in
    *"SSH PrivateKey"*)
        print_text_in_color "$ICyan" "SSH-PrivateKey Hardening wurde ausgewählt..."
        PrivKey
    ;;&
    *"Advantage"*)
        print_text_in_color "$ICyan" "Ubuntu Advantage wurde ausgewählt..."
        Advantage
    ;;&
    *"Fail2Ban"*)
        print_text_in_color "$ICyan" "Fail2Ban-Service wurde ausgewählt..."
        Fail2Ban
    ;;&
    *"SSH-Port"*)
        print_text_in_color "$ICyan" "Änderung des SSH-Ports wurde ausgewählt..."
        Advantage
    ;;&
    *"Multi-Faktor-Authentifizierung"*)
        print_text_in_color "$ICyan" "Multi-Faktor-Authentifizierung gewählt...."
        GAuth
    ;;&

    *)
    ;;
esac
exit
