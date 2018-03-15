#!/bin/bash

# Require these:
# http://172.16.42.1:1471
# http://172.16.42.1:1471/#/modules/Setup
#
# sudo apt install macchanger hostapd dnsmasq rfkill aircrack-ng
#
# If using the tl-wn722n v2 (not recommended):
# For wlan1 (drivers and modified hostapd)
# sudo wget http://www.fars-robotics.net/install-wifi -O /usr/bin/install-wifi
# sudo chmod +x /usr/bin/install-wifi
# wget http://www.daveconroy.com/wp3/wp-content/uploads/2013/07/hostapd.zip
# unzip hostapd.zip 
# mv /usr/sbin/hostapd /usr/sbin/hostapd.bak
# mv hostapd /usr/sbin/hostapd
# chmod 755 /usr/sbin/hostapd
#
#--------------- START SCRIPT NETWORK INTERFACES ------------------
#
#------ Variables --------#
upstream=wlan0
phy=wlan1

#------ Get started --------#
sudo service network-manager stop
sudo rfkill unblock wlan
sudo mkdir -p /etc/pinespoof
sudo chown -R pi:pi /etc/pinespoof

#------ Set mac to atheros --------#
macchanger --mac=00:B0:52::61:AC $phy

#------ Set DNS  --------#
echo “nameserver 8.8.8.8” > /etc/resolv.conf
echo “nameserver 8.8.4.4” >> /etc/resolv.conf

#------ For NAT routing tables  --------#
#echo 1 > /proc/sys/net/ipv4/ip_forward
#iptables --policy INPUT ACCEPT
#iptables --policy FORWARD ACCEPT
#iptables --policy OUTPUT ACCEPT
#iptables -F
#iptables -t nat -F
#iptables -t nat -A POSTROUTING -o $upstream -j MASQUERADE
#iptables -A FORWARD -i $phy -o $upstream -j ACCEPT

#------ PORT FORWARD KIPPO  --------#
sudo iptables -t nat -A PREROUTING -i $phy -d 172.16.42.1 -p tcp --dport 22 -j REDIRECT --to-port 4633

#------ Network interfaces  --------#
cat << EOF > /etc/network/interfaces
auto lo

iface lo inet loopback

iface eth0 inet dhcp

# Upstream interface
allow-hotplug wlan0
iface wlan0 inet manual
    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf

# Honeypot interface
allow-hotplug wlan1
iface wlan1 inet static  
    address 172.16.42.1
    netmask 255.255.255.0
    network 172.16.42.0
    broadcast 172.16.42.255
EOF

#------ HOSTAPD --------#
cat << EOF > /etc/pinespoof/hostapd.conf
interface=wlan1
driver=rtl871xdrv
# Change last 4 of ssid
ssid=Pineapple_61AC
hw_mode=g
channel=6
auth_algs=1
wmm_enabled=0
EOF

#------ DNSMASQ --------#
cat << EOF > /etc/pinespoof/dnsmasq.conf
interface=wlan1
no-dhcp-interface=lo,wlan0
bind-interfaces
server=8.8.8.8
bogus-priv
dhcp-range=172.16.42.100,172.16.42.254,1h
dhcp-option=6,8.8.8.8,8.8.4.4  #dns
EOF

#------ Bring up wlan1 --------#
ifconfig $phy up 172.16.42.1/24 up

#------ Start services --------#
sudo dnsmasq -z -C /etc/pinespoof/dnsmasq.conf -i $phy -I lo
sudo hostapd /etc/pinespoof/hostapd.conf&

#------ Cowrie --------#
sudo -u cowrie "/home/cowrie/cowrie/bin/cowrie start"