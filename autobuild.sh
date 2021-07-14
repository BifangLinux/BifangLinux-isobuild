#!/bin/bash
USER="bifanglinux"

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

ISO="Bifanglinux-$(date +%y%m)_x86_64.iso"
SIG="Bifanglinux-$(date +%y%m)_x86_64.iso.sig"
MD5SUM="md5sum"

#Build ISO File
package=archiso
if pacman -Qs $package > /dev/null ; then
    echo "The package $package is installed"
else
    echo "Installing package $package"
    pacman -S $package --noconfirm
fi

source build.sh -v

chown $USER out/
cd out/

#create md5sum and signature file
echo "create MD5 Checksum"
sudo -u $USER md5sum $ISO >> md5sum
echo "Signing ISO Image..."
sudo -u $USER gpg --detach-sign --no-armor $ISO

