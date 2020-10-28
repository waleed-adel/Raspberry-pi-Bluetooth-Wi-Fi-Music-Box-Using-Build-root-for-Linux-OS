#!/bin/sh

set -u
set -e

networkName="brmp3player"

# hostname to easily connect by name
#echo "$networkName" > output/target/etc/hostname

# hostname to easily connect by name
#echo "127.0.0.1    localhost" > output/target/etc/hosts
#echo "127.0.1.1    $networkName" >> output/target/etc/hosts

# Add a console on tty1
if [ -e ${TARGET_DIR}/etc/inittab ]; then
    grep -qE '^tty1::' ${TARGET_DIR}/etc/inittab || \
    sed -i '/GENERIC_SERIAL/a\
tty1::respawn:/sbin/getty -L  tty1 0 vt100 # HDMI console' ${TARGET_DIR}/etc/inittab
fi

#############################################################################################################################################
## PermitRootLogin for ssh
sed -i '/#PermitRootLogin prohibit-password/c\PermitRootLogin yes' output/target/etc/ssh/sshd_config 

## change prompt to MP3_Shell> with red color
sed -i "/export PS1=/c\                 export PS1='\\\e[0;31mMP3_Shell>\\\e[m '"  output/target/etc/profile

## aliasing ls -lah
cat output/target/etc/profile | grep 'alias las="ls -lah"' 1>/dev/null || (
   echo 'alias las="ls -lah"' >> output/target/etc/profile
)

# greet the user with "Welcome to BuildRoot MP3 Player" on each shell session
#cat output/target/etc/profile | grep 'echo "Welcome to BuildRoot MP3 Player"' 1>/dev/null || (
#   echo 'echo "Welcome to BuildRoot MP3 Player"' >> output/target/etc/profile
#)
cat output/target/etc/profile | grep 'wall -n "Welcome to BuildRoot MP3 Player"' 1>/dev/null || (
   echo 'wall -n "Welcome to BuildRoot MP3 Player"' >> output/target/etc/profile
)

# alias "play", "pause", "next", "previous"
cat output/target/etc/profile | grep 'alias play=' 1>/dev/null || (
   echo "alias play='echo 1 > /root/superMusic/somethingChanged2'" >> output/target/etc/profile
)
cat output/target/etc/profile | grep 'alias pause=' 1>/dev/null || (
   echo "alias pause='echo 1 > /root/superMusic/somethingChanged2'" >> output/target/etc/profile
)
cat output/target/etc/profile | grep 'alias next=' 1>/dev/null || (
   echo "alias next='echo 2 > /root/superMusic/somethingChanged2'" >> output/target/etc/profile
)
cat output/target/etc/profile | grep 'alias previous=' 1>/dev/null || (
   echo "alias previous='echo 3 > /root/superMusic/somethingChanged2'" >> output/target/etc/profile
)
cat output/target/etc/profile | grep 'alias shuffle=' 1>/dev/null || (
   echo "alias shuffle='echo 4 > /root/superMusic/somethingChanged2'" >> output/target/etc/profile
)


# copy music files from postBuild dir
if [ ! -d "${TARGET_DIR}/root/superMusic" ]; then
    sudo mkdir ${TARGET_DIR}/root/superMusic
fi

sudo cp $(dirname $0)/playmusic/S50-playmusic-daemon-service ${TARGET_DIR}/etc/init.d/
sudo chmod 777 ${TARGET_DIR}/etc/init.d/S50-playmusic-daemon-service
sudo cp $(dirname $0)/playmusic/playmusic* ${TARGET_DIR}/root/superMusic/
sudo cp $(dirname $0)/playmusic/detectUSB ${TARGET_DIR}/root/superMusic/
sudo chmod -R 777 ${TARGET_DIR}/root

################# Enabe Wifi #######################################
if [ ! -d "${TARGET_DIR}/etc/wpa_supplicant" ]; then
    sudo mkdir ${TARGET_DIR}/etc/wpa_supplicant
fi
sudo chmod 777 ${TARGET_DIR}/etc/wpa_supplicant
if [ ! -f "${TARGET_DIR}/etc/wpa_supplicant/wpa_supplicant.conf" ]; then
    sudo touch ${TARGET_DIR}/etc/wpa_supplicant/wpa_supplicant.conf
fi
sudo chmod 777 ${TARGET_DIR}/etc/wpa_supplicant/wpa_supplicant.conf
sudo cp package/busybox/S10mdev ${TARGET_DIR}/etc/init.d/S10mdev
sudo chmod 777 ${TARGET_DIR}/etc/init.d/S10mdev
sudo cp package/busybox/mdev.conf ${TARGET_DIR}/etc/mdev.conf
sudo chmod 777 ${TARGET_DIR}/etc/mdev.conf

#sudo chmod 777 ~/buildroot/rootFs_Overlay_mp3player/myApplications/printHello.o
#. ~/buildroot/rootFs_Overlay_mp3player/myApplications/printHello.o


cat > output/target/etc/network/interfaces << EOL
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
### ### ###                                                ### ### ###
### ### ### WARNING: don't put comments beside any command ### ### ###
### ### ###                                                ### ### ###
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
### ###                                                                                ### ### ###
### ### It is NOT recommended to use the same network on different adapters/interfaces ### ### ###
### https://community.spiceworks.com/topic/228045-wireless-conflicting-with-hard-wired-ethernet ###
### ###                                                                                ### ### ###
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###


### Loopback adapter ###

# enable adapter
auto lo

# set adapter configuration as loopback
iface lo inet loopback


### Ethernet adapter ###

# enable adapter
auto eth0

# set adapter configuration as static
iface eth0 inet static
#iface eth0 inet dhcp

   # give the adapter some time to bootup
   # https://code.kodo.org.uk/dom/buildroot/commit/ccc52c8183730a6b7f498d371520e881dfb41668
   wait-delay 30

   # pre/post adapter bootup scripts
   pre-up /etc/network/nfs_check

   # IP/address of this host
   address 192.168.5.6

   # mask defining the network bits 1's and host bits 0's
   netmask 255.255.255.0

   # IP to fallback to if a host is unreachable
   gateway 192.168.5.1


### WiFi adapter ###

# enable adapter
auto wlan0

# set adapter configuration as static
iface wlan0 inet static
#iface wlan0 inet dhcp

   # give the adapter some time to bootup
   # https://code.kodo.org.uk/dom/buildroot/commit/ccc52c8183730a6b7f498d371520e881dfb41668
   wait-delay 30

   # pre/post adapter bootup scripts
   pre-up wpa_supplicant -B -Dwext -iwlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf
   post-down killall -q wpa_supplicant

   # IP/address of this host
   address 192.168.1.6

   # mask defining the network bits 1's and host bits 0's
   netmask 255.255.255.0

   # IP to fallback to if a host is unreachable
   gateway 192.168.1.1


# set ay interface configuration as automatic (DHCP) by default
iface default inet dhcp

EOL


cat > output/target/etc/wpa_supplicant/wpa_supplicant.conf << EOL
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=EG

network={
   ssid="uname"
   psk="123456qaZ!@#"
   
   # this is needed if the ssid is not being broadcasted
   scan_ssid=1
   
   key_mgmt=WPA-PSK
}

EOL


