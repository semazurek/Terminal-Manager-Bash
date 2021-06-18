#!/bin/bash

# Funkcja sprawdzajaca wymagane moduly do działania programu
check_install () {
clear
STATUS_OK=$(dpkg-query -W --showformat='${Status}\n' $WYMAGANE|grep "install ok installed")
echo Sprawdzanie pakietu potrzebnego w skrypcie: $WYMAGANE: $STATUS_OK
if [ "" = "$STATUS_OK" ]; then
  echo "Brak: $WYMAGANE. Instalowanie: $WYMAGANE."
  sudo apt-get --yes install $WYMAGANE 
fi
}

#Okienko menu wyboru
WYMAGANE="dialog"
check_install

# Dyski/napędy informacje nazwa/pojemnosc SCSI
WYMAGANE="lsscsi"
check_install

#Informacje o systemie
WYMAGANE="lshw"
check_install

#Remote Desktop VNC/RDP
WYMAGANE="remmina"
check_install

#Remote Android ADB-DEV OPS
WYMAGANE="scrcpy"
check_install

#Xprobe2 IP host OS information
WYMAGANE="xprobe"
check_install


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
BACKTITLE="Terminal Manager v2.1.5.20"
# 2021.05.20 Created by Rikey
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
      	   	  sudo apt-get update
      	   	  sudo apt-get upgrade -y
      	   	  sudo apt-get dist-upgrade -y
      	    	 ;;
      	       9)
      	    	 clear
      	    	 sudo apt-get autoclean -y
      	    	 sudo apt-get clean -y
      	    	 sudo apt-get autoremove -y
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
