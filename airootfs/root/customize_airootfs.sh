#!/bin/bash

USER="bifanglinuxiso"
OSNAME="bifanglinux"

function localeGenFunc() {
    # Set locales
    sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
    locale-gen
}

function setTimeZoneAndClockFunc() {
    # Timezone
    ln -sf /usr/share/zoneinfo/UTC /etc/localtime

    # Set clock to UTC
    hwclock --systohc --utc
}

function setDefaultsFunc() {
    #set default Browser
    export _BROWSER=firefox
    echo "BROWSER=/usr/bin/${_BROWSER}" >> /etc/environment
    echo "BROWSER=/usr/bin/${_BROWSER}" >> /etc/profile

    #Set Nano Editor
    export _EDITOR=nano
    echo "EDITOR=${_EDITOR}" >> /etc/environment
    echo "EDITOR=${_EDITOR}" >> /etc/profile
}

function initkeysFunc() {
    #Setup Pacman
    pacman-key --init
    pacman-key --populate archlinux

    #re/add swagarch gpg manually (fix live mode issues)
    pacman-key -f EC5D6021
    pacman-key -r EC5D6021
    pacman-key --lsign-key EC5D6021
}

function fixHaveged(){
    systemctl start haveged
    systemctl enable haveged

    rm -fr /etc/pacman.d/gnupg
}

function fixPermissionsFunc() {
    #fix permissions
    chown root:root /
    chown root:root /etc
    chown root:root /etc/default
    chown root:root /usr
    chmod 755 /etc
}

function enableServicesFunc() {
    systemctl enable org.cups.cupsd.service
    systemctl enable avahi-daemon.service
    systemctl enable vboxservice.service
    systemctl enable bluetooth.service
    systemctl -fq enable NetworkManager-wait-online.service
    systemctl mask systemd-rfkill@.service
    systemctl mask systemd-rfkill.service
    systemctl mask systemd-rfkill.socket
    systemctl set-default graphical.target
}

function addCalamaresToPlankDockFunc() {
    dockItem="/home/liveuser/.config/plank/dock1/launchers/Calamares.dockitem"

    echo "[PlankDockItemPreferences]" >> $dockItem
    echo "Launcher=file:///usr/share/applications/calamares.desktop" >> $dockItem

    chown liveuser $dockItem
}

function fixWifiFunc() {
    #Wifi not available with networkmanager (BugFix)
    #https://github.com/SwagArch/swagarch-build/issues/8
    #https://bifanglinux.github.io
    su -c 'echo "" >> /etc/NetworkManager/NetworkManager.conf'
    su -c 'echo "[device]" >> /etc/NetworkManager/NetworkManager.conf'
    su -c 'echo "wifi.scan-rand-mac-address=no" >> /etc/NetworkManager/NetworkManager.conf'
}

function fontFix() {
    # To disable scaling of bitmap fonts (which often makes them blurry) 
    rm -rf /etc/fonts/conf.d/10-scale-bitmap-fonts.conf
}

function configRootUserFunc() {
    usermod -s /usr/bin/bash root
    echo 'export PROMPT_COMMAND=""' >> /root/.bashrc
    chmod 700 /root
}

function createLiveUserFunc () {
    # add groups autologin and nopasswdlogin (for lightdm autologin)
    groupadd -r autologin
    groupadd -r nopasswdlogin

    # add liveuser
    id -u $USER &>/dev/null || useradd -m $USER -g users -G "adm,audio,floppy,log,network,rfkill,scanner,storage,optical,autologin,nopasswdlogin,power,sambashare,wheel"
    passwd -d $USER
    echo 'Live User Created'
}

function editOrCreateConfigFilesFunc () {
    # Locale
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    echo "LC_COLLATE=C" >> /etc/locale.conf

    # Vconsole
    echo "KEYMAP=us" > /etc/vconsole.conf
    echo "FONT=" >> /etc/vconsole.conf

    # Hostname
    echo "bifanglinux" > /etc/hostname

    sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist
    sed -i 's/#\(Storage=\)auto/\1volatile/' /etc/systemd/journald.conf
}

function doNotDisturbTheLiveUserFunc() {
    #delete old config file
    pathToPerchannel="/home/$USER/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-notifyd.xml"
    rm -rf $pathToPerchannel
    #create a new file
    touch $pathToPerchannel
    echo '<?xml version="1.0" encoding="UTF-8"?>' >> $pathToPerchannel
    echo '' >> $pathToPerchannel
    echo '<channel name="xfce4-notifyd" version="1.0">' >> $pathToPerchannel
    echo '  <property name="notify-location" type="uint" value="3"/>' >> $pathToPerchannel
    echo '  <property name="do-not-disturb" type="bool" value="true"/>' >> $pathToPerchannel
    echo '</channel>' >> $pathToPerchannel
}

function fixHibernateFunc() {
    sed -i 's/#\(HandleSuspendKey=\)suspend/\1ignore/' /etc/systemd/logind.conf
    sed -i 's/#\(HandleHibernateKey=\)hibernate/\1ignore/' /etc/systemd/logind.conf
    sed -i 's/#\(HandleLidSwitch=\)suspend/\1ignore/' /etc/systemd/logind.conf
}

function umaskFunc() {
    set -e -u
    umask 022
}

umaskFunc
localeGenFunc
setTimeZoneAndClockFunc
editOrCreateConfigFilesFunc
configRootUserFunc
createLiveUserFunc
doNotDisturbTheLiveUserFunc
setDefaultsFunc
addCalamaresToPlankDockFunc
enableServicesFunc
fontFix
fixWifiFunc
fixPermissionsFunc
fixHibernateFunc
fixHaveged
initkeysFunc
