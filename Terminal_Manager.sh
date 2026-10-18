#!/bin/bash

# 1. Wykrywanie dostępnego menedżera pakietów w systemie
if command -v apt-get &> /dev/null; then
    PKG_MANAGER="apt"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
else
    echo "Error: Supported package manager (apt or dnf) not found."
    exit 1
fi

# 2. Uniwersalna funkcja sprawdzająca i instalująca pakiety
check_install () {
    clear
    local PROGRAM="$1"
    local PACKAGE_NAME="$1"
    local COMMAND_NAME="$1"
    
    # Mapowanie nazw dla narzędzi różniących się między dystrybucjami
    if [ "$PKG_MANAGER" = "dnf" ]; then
        if [ "$PROGRAM" = "xprobe" ]; then
            PACKAGE_NAME="xprobe2"
            COMMAND_NAME="xprobe2"
        fi
    fi
    
    echo "Checking required package: $PROGRAM..."

    # Sprawdzenie, czy polecenie jest już dostępne w systemie (używamy COMMAND_NAME)
    if ! command -v "$COMMAND_NAME" &> /dev/null; then
        echo "Missing: $PROGRAM. Installing: $PACKAGE_NAME..."
        
        if [ "$PKG_MANAGER" = "apt" ]; then
            sudo apt-get --yes install "$PACKAGE_NAME"
        elif [ "$PKG_MANAGER" = "dnf" ]; then
            # Specjalna obsługa dla scrcpy na Fedorze (wymaga repozytorium COPR)
            if [ "$PROGRAM" = "scrcpy" ]; then
                sudo dnf copr enable -y zeno/scrcpy
            fi
            sudo dnf -y install "$PACKAGE_NAME"
        fi
    else
        echo "Package $PROGRAM is already installed [OK]."
    fi
}

# --- Wywołanie funkcji dla poszczególnych narzędzi ---

# Okienko menu wyboru
check_install "dialog"

# Dyski/napędy informacje nazwa/pojemnosc SCSI
check_install "lsscsi"

# Informacje o systemie
check_install "lshw"

# Remote Desktop VNC/RDP
check_install "remmina"

# Remote Android ADB-DEV OPS
check_install "scrcpy"

# Xprobe2 IP host OS information
check_install "xprobe"
# Przypisanie zmiennych
user=$(whoami)
host=$(hostname)
ip_local=$(hostname -I)
y=0 #zmienna pomocnicza pętli głównej

# Główna pętla skryptu 
# Wykonuje się póki y nie jest równe 1
while [ "$y" != "1" ]; do
clear
HEIGHT=16
WIDTH=55
CHOICE_HEIGHT=4
BACKTITLE="Terminal Manager v2.6.10.18"
# 2021.05.20 Created by Rikey
# 2026.10.19 Updated
TITLE="Terminal Manager"
MENU="User: ${user^} Host: $host IP: $ip_local"
OPTIONS=(1 "Show Information About System"
         2 "Show Disk Storage Information"
         3 "User Management (Create/Edit/Delete)"
         4 "Remote Control (RDP/VNC/SSH)"
         5 "Remote Android (USB-ADB)"
         6 "Hosts Scan/Host OS Information (Nmap)"
         7 "WiFi HotSpot (Setup/ON/OFF)"
         8 "Full Update & Upgrade"
         9 "Clean Trash/Temp/Cache"
         )

CHOICE=$(dialog --clear --backtitle "$BACKTITLE" --title "$TITLE" --menu "$MENU" $HEIGHT $WIDTH $CHOICE_HEIGHT "${OPTIONS[@]}" 2>&1 >/dev/tty)

clear
case $CHOICE in
        1)
            sudo lshw -html > Information.html
            if test -f "Information.html"; then
            firefox Information.html
            fi
            ;;
        2)
            echo
            lsblk
            echo
            lsscsi -s
            echo 
            read -p "Press any key to continue"
            ;;
        3)
            MENU="User Management (Create/Edit/Delete)"
		OPTIONS=(1 "Create New User"
   		         2 "Edit User Password"
    	  		 3 "Delete User"
    	  		 4 "Set user as Root/Admin"
    			 )
    			 
    		CHOICE=$(dialog --clear --backtitle "$BACKTITLE" --title "$TITLE" --menu "$MENU" $HEIGHT $WIDTH $CHOICE_HEIGHT "${OPTIONS[@]}" 2>&1 >/dev/tty)
    		
    		case $CHOICE in
      		  1) 
      		  	read -p "Type new user: " name
      		  	sudo adduser $name
      		     	read -p "Press any key to continue"
      		  ;;
      		  2) 
      		  	read -p "User to set password: " name
      		  	sudo passwd $name
      		  	read -p "Press any key to continue"
      		  	
      		  ;;
      		  3) 
      		  	read -p "Type user to delete: " name
      		  	sudo deluser $name
      		  	read -p "Press any key to continue"
      		  ;;
      		  4)
      		  	read -p "Type user to root: " name
      		  	sudo usermod -aG sudo $name
      		  	read -p "Press any key to continue"
      		  ;;
      		  esac
            ;;
          4)
            remmina -k
            ;;
           5)
           sudo scrcpy           
           ;;
           6)
           MENU="Scan for Hosts/Information"
		OPTIONS=(1 "Scan for active hosts"
   		         2 "Information about host"
    			 )
    			 
    		CHOICE=$(dialog --clear --backtitle "$BACKTITLE" --title "$TITLE" --menu "$MENU" $HEIGHT $WIDTH $CHOICE_HEIGHT "${OPTIONS[@]}" 2>&1 >/dev/tty)
    		
    		case $CHOICE in
    	   1)
    	   echo "Local IP: $ip_local"
           read -p "Type network with prefix (e.g. 10.0.0.1/24): " network
           while [ "$y" != "1" ]; do
           sudo nmap -sn $network > Hosts.txt
           clear
           cat Hosts.txt
           sleep 5
           done
           ;;
           2)
           read -p "Type host/IP for information: " hostlook
           clear
           sudo xprobe2 $hostlook
           echo "---------------------------------------"
	   sudo nmap -sS -O $hostlook
           echo
           read -p "Press any key to continue"
           ;;
           esac
           ;;
           7)
           	MENU="WiFi HotSpot (Setup/ON/OFF)"
		OPTIONS=(1 "Create AP"
   		         2 "Turn ON AP"
   		         3 "Turn OFF AP"
   		         4 "Delete AP"
    			 )
    			 
    		CHOICE=$(dialog --clear --backtitle "$BACKTITLE" --title "$TITLE" --menu "$MENU" $HEIGHT $WIDTH $CHOICE_HEIGHT "${OPTIONS[@]}" 2>&1 >/dev/tty)
    		
    		case $CHOICE in
      		  1) 
      		  	read -p "Type name of HotSpot(SSID): " ssid
      		  	read -p "Type password of HotSpot(KEY): " pass
      		  	nmcli con delete Hotspot
      		  	clear
      		  	nmcli con add type wifi ifname wlan0 con-name Hotspot autoconnect yes ssid $ssid
      		  	nmcli con modify Hotspot 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared
      		  	nmcli con modify Hotspot wifi-sec.key-mgmt wpa-psk
      		  	nmcli con modify Hotspot wifi-sec.psk "$pass"
      		  	nmcli con up Hotspot
      		     	read -p "Press any key to continue"
      		  ;;
      		  2) 
      		  	nmcli con up Hotspot
      		  ;;
      		  3) 
      		  	nmcli con down Hotspot
      		  ;;
      		  4)
      		  	nmcli con down Hotspot
      		  	nmcli con delete Hotspot
      		  ;;
      		  esac
      			;;
			  8)
    			clear
    			if [ "$PKG_MANAGER" = "apt" ]; then
        			sudo apt-get update
        			sudo apt-get upgrade -y
        			sudo apt-get dist-upgrade -y
    			elif [ "$PKG_MANAGER" = "dnf" ]; then
        			sudo dnf check-update
        			sudo dnf upgrade -y
        			sudo dnf distro-sync -y
    			fi
    			;;
      	      9)
    			clear
    			if [ "$PKG_MANAGER" = "apt" ]; then
        			sudo apt-get autoclean -y
        			sudo apt-get clean -y
        			sudo apt-get autoremove -y
    			elif [ "$PKG_MANAGER" = "dnf" ]; then
        			sudo dnf clean packages -y
        			sudo dnf clean all -y
        			sudo dnf autoremove -y
    			fi
    			rm -rf ~/.cache/thumbnails/*
    			sudo journalctl --vacuum-time=3d
    			set -eu
    			snap list --all | awk '/disabled/{print $1, $3}' |
    			while read snapname revision; do
        		snap remove "$snapname" --revision="$revision"
    			done
    				;;
esac

done
