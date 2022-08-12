#!/bin/bash

#### Einige Teile dieses Scripts stammen von hier: https://raw.githubusercontent.com/nextcloud/vm/master/lib.sh ####

MENU_GUIDE="Navigieren Sie mit den Pfeiltasten und bestätigen Sie Ihhre Eingabe. Abbrechen mit [ESC]."
TITLE="Veeam Backup Hardened Repository - $(date +%Y)"
SYSVENDOR=$(cat /sys/devices/virtual/dmi/id/sys_vendor)
ISSUES="https://github.com/ex0sandata/veeamhardenedlinuxrepo/issues"
SCRIPTS=/var/scripts

# Ubuntu OS
DISTRO=$(lsb_release -sr)
CODENAME=$(lsb_release -sc)
KEYBOARD_LAYOUT=$(localectl status | grep "Layout" | awk '{print $3}')

function spinner_loading() {
    printf '['
    while ps "$!" > /dev/null; do
        echo -n '⣾⣽⣻'
        sleep '.7'
    done
    echo ']'
}

#### Install_if_not Installationsroutine ####
function install_if_not() {
    if ! dpkg-query -W -f='${Status}' "${1}" | grep -q "ok installed"
    then
        apt-get update -q4 & spinner_loading && RUNLEVEL=1 apt-get install "${1}" -y
    fi
}

function any_key() {
    local PROMPT="$1"
    read -r -sn 1 -p "$(printf "%b" "${IGreen}${PROMPT}${Color_Off}")";echo
}


function print_text_in_color() {
    printf "%b%s%b\n" "$1" "$2" "$Color_Off"
}

if [[ $EUID -ne 0 ]]; then
    set -e
    print_text_in_color "$IRed" "Skript nicht als sudo / root ausgeführt, bitte Passwort eingeben:"
    sudo "$0"
    exit $?
fi

function msg_box() {
    [ -n "$2" ] && local SUBTITLE=" - $2"
    whiptail --title "$TITLE$SUBTITLE" --msgbox "$1" "$WT_HEIGHT" "$WT_WIDTH" 3>&1 1>&2 2>&3
}

function input_box() {
    [ -n "$2" ] && local SUBTITLE=" - $2"
    local RESULT && RESULT=$(whiptail --title "$TITLE$SUBTITLE" --nocancel --inputbox "$1" "$WT_HEIGHT" "$WT_WIDTH" 3>&1 1>&2 2>&3)
    echo "$RESULT"
}

function download_script() {
    rm -rf /var/scripts
    curl -sLO https://raw.githubusercontent.com/ex0sandata/VeeamHardenedLinuxRepo/main/{$1}
}

function run_script() {
    if [ -z "$(ls -A /var/scripts)" ]
    then
        bash "${SCRIPTS}/${1}.sh"
    else
        print_text_in_color "$IRed" "Running ${1} failed"
        sleep 2
        print_text_in_color "$IRed" "Versuche Skripts zu downloaden....."
        download_script ${1}
    fi
}


#### requirement check fuer veeam: 2 Cores, 4GB RAM, 64Bit-OS ####
function requirement_failed (){
    msg_box "Dieser Server besitzt nicht die Mindestanforderungen fuer Veeam Hardened Repository. Link zu den Minimumsanforderungen für die Hardware:
    https://helpcenter.veeam.com/docs/backup/vsphere/system_requirements.html?ver=110#backup-repository-server"
    exit 1
}

#### Check Ubuntu version ####

# function version (){
#     cat /etc/os-release | awk '{print $2}' | sed -n 1p
# }

function check_distro_version() {

    # Ubuntu 18.04 bionic oder Ubuntu 20.04 focal werden unterstuetzt

    if [ "${CODENAME}" == "jammy" ] || [ "${CODENAME}" == "focal" || [ "${CODENAME}" == "bionic" ]
    then
        print_text_in_color "$IBlue" "CODENAME = $CODENAME"
        OS=1
    elif lsb_release -i | grep -ic "Ubuntu" &> /dev/null
    then
        print_text_in_color "$IBlue" "LSB_RELEASE = Ubuntu"
        OS=1
    elif uname -a | grep -ic "bionic" &> /dev/null || uname -a | grep -ic "focal" &> /dev/null  || uname -a | grep -ic "jammy" &> /dev/null
    then
        print_text_in_color "$IBlue" "uname == bionic || focal || jammy"
        OS=1
    elif uname -v | grep -ic "Ubuntu" &> /dev/null
    then
        print_text_in_color "$IBlue" "uname -v == ubuntu"
        OS=1    
    fi

    if [ $(uname -m) = x86_64 ] 
    then
        print_text_in_color "$IBlue" "uname -m == x86_64"
        OS=1
    fi

    if [ "$OS" != 1 ]
    then
        msg_box "Dieses Script kann nur unter Ubuntu Server LTS auf 64-bit installiert werden. Bitte nur auf diesem OS ausführen.
        Der Downloadlink ist hier: https://www.ubuntu.com/download/server"
        requirement_failed
        exit 1
    fi

    print_text_in_color "$IGreen" "OS-Checks bestanden, Distro = $DISTRO, OS = $OS"
}

function ram_check (){

    #### RAM >4 GB ####
    # Test RAM size
    # Call it like this: ram_check [amount of min RAM in GB] [for which program]
    # Example: ram_check 4 Veeam
    install_if_not bc
    # First, we need to check locales, since the functino depends on it.
    # When we know the locale, we can then calculate mem available without any errors.
    if locale | grep -c "C.UTF-8"
    then
        mem_available="$(awk '/MemTotal/{print $2}' /proc/meminfo)"
        mem_available_gb="$(LC_NUMERIC="C.UTF-8" printf '%0.2f\n' "$(echo "scale=3; $mem_available/(1024*1024)" | bc)")"
    elif locale | grep -c "en_US.UTF-8"
    then
        mem_available="$(awk '/MemTotal/{print $2}' /proc/meminfo)"
        mem_available_gb="$(LC_NUMERIC="en_US.UTF-8" printf '%0.2f\n' "$(echo "scale=3; $mem_available/(1024*1024)" | bc)")"
    fi

    # Now check required mem
    mem_required="$((${1}*(924*1024)))" # 100MiB/GiB margin and allow 90% to be able to run on physical machines
    
    print_text_in_color "$IBlue" "Memory Available = $mem_available"
    print_text_in_color "$IBlue" "Memory Available in GB = $mem_available_gb"
    print_text_in_color "$IBlue" "Memory Required = $mem_required"

    if [ "${mem_available}" -lt "${mem_required}" ]
    then
        print_text_in_color "$IRed" "Error: ${1} GB RAM required to install ${2}!" >&2
        print_text_in_color "$IRed" "Current RAM is: ($mem_available_gb GB)" >&2
        sleep 3
        requirement_failed
    else
        print_text_in_color "$IGreen" "RAM for ${2} OK! ($mem_available_gb GB)"
    fi
    
}

#### Test number of CPU, muss >2 sein ####
# Call it like this: cpu_check [amount of min CPU] [for which program]
# Example: cpu_check 2 
function cpu_check() {
    nr_cpu="$(nproc)"
    if [ "${nr_cpu}" -lt "${1}" ]
    then
        print_text_in_color "$IRed" "Error: ${1} CPU required to install ${2}!" >&2
        print_text_in_color "$IRed" "Current CPU: ($((nr_cpu)))" >&2
        sleep 1
        exit 1
    else
        print_text_in_color "$IGreen" "CPU for ${2} OK! ($((nr_cpu)))"
    fi
}


# Whiptail auto-size
function calc_wt_size() {
    WT_HEIGHT=17
    WT_WIDTH=$(tput cols)

    if [ -z "$WT_WIDTH" ] || [ "$WT_WIDTH" -lt 60 ]; then
        WT_WIDTH=80
    fi
    if [ "$WT_WIDTH" -gt 178 ]; then
        WT_WIDTH=120
    fi
    WT_MENU_HEIGHT=$((WT_HEIGHT-7))
    export WT_MENU_HEIGHT
}

function yesno_box_yes() {
    [ -n "$2" ] && local SUBTITLE=" - $2"
    if (whiptail --title "$TITLE$SUBTITLE" --yesno "$1" "$WT_HEIGHT" "$WT_WIDTH" 3>&1 1>&2 2>&3)
    then
        return 0
    else
        return 1
    fi
}

function yesno_box_no() {
    [ -n "$2" ] && local SUBTITLE=" - $2"
    if (whiptail --title "$TITLE$SUBTITLE" --defaultno --yesno "$1" "$WT_HEIGHT" "$WT_WIDTH" 3>&1 1>&2 2>&3)
    then
        return 0
    else
        return 1
    fi
}



# Check if process is runnnig: is_process_running dpkg
function is_process_running() {
    PROCESS="$1"
    
    print_text_in_color "$IPurple" "Service ${PROCESS} wird abgefragt"
    if [ $(pgrep -c $PROCESS) = 0 ]; then
        print_text_in_color "$IBlue" "${PROCESS} ist nicht aktiv."
        return
    else 
        while [ $(pgrep -c $PROCESS) != 0 ]
        do
            print_text_in_color "$ICyan" "${PROCESS} ist noch aktiv, bitte warten...."
            sleep 20
        done
    fi
}

# Check if program is installed (is_this_installed apache2)
function is_this_installed() {
if dpkg-query -W -f='${Status}' "${1}" | grep -q "ok installed"
    then
        return 0
    else
        return 1
    fi
}


## bash Farben:
# Reset
Color_Off='\e[0m'       # Text Reset

# Regular Colors
Black='\e[0;30m'        # Black
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Yellow='\e[0;33m'       # Yellow
Blue='\e[0;34m'         # Blue
Purple='\e[0;35m'       # Purple
Cyan='\e[0;36m'         # Cyan
White='\e[0;37m'        # White

# Bold
BBlack='\e[1;30m'       # Black
BRed='\e[1;31m'         # Red
BGreen='\e[1;32m'       # Green
BYellow='\e[1;33m'      # Yellow
BBlue='\e[1;34m'        # Blue
BPurple='\e[1;35m'      # Purple
BCyan='\e[1;36m'        # Cyan
BWhite='\e[1;37m'       # White

# Underline
UBlack='\e[4;30m'       # Black
URed='\e[4;31m'         # Red
UGreen='\e[4;32m'       # Green
UYellow='\e[4;33m'      # Yellow
UBlue='\e[4;34m'        # Blue
UPurple='\e[4;35m'      # Purple
UCyan='\e[4;36m'        # Cyan
UWhite='\e[4;37m'       # White

# Background
On_Black='\e[40m'       # Black
On_Red='\e[41m'         # Red
On_Green='\e[42m'       # Green
On_Yellow='\e[43m'      # Yellow
On_Blue='\e[44m'        # Blue
On_Purple='\e[45m'      # Purple
On_Cyan='\e[46m'        # Cyan
On_White='\e[47m'       # White

# High Intensity
IBlack='\e[0;90m'       # Black
IRed='\e[0;91m'         # Red
IGreen='\e[0;92m'       # Green
IYellow='\e[0;93m'      # Yellow
IBlue='\e[0;94m'        # Blue
IPurple='\e[0;95m'      # Purple
ICyan='\e[0;96m'        # Cyan
IWhite='\e[0;97m'       # White

# Bold High Intensity
BIBlack='\e[1;90m'      # Black
BIRed='\e[1;91m'        # Red
BIGreen='\e[1;92m'      # Green
BIYellow='\e[1;93m'     # Yellow
BIBlue='\e[1;94m'       # Blue
BIPurple='\e[1;95m'     # Purple
BICyan='\e[1;96m'       # Cyan
BIWhite='\e[1;97m'      # White

# High Intensity backgrounds
On_IBlack='\e[0;100m'   # Black
On_IRed='\e[0;101m'     # Red
On_IGreen='\e[0;102m'   # Green
On_IYellow='\e[0;103m'  # Yellow
On_IBlue='\e[0;104m'    # Blue
On_IPurple='\e[0;105m'  # Purple
On_ICyan='\e[0;106m'    # Cyan
On_IWhite='\e[0;107m'   # White
