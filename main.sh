#!/bin/bash

#THIS MUST BE EXECUTED AT THE SAME DIRECTORY AS AUTOINSTALL file


intial_directory=$(pwd)
ram="8142"
cpu="4"


cd /tmp
wget -nc http://releases.ubuntu.com/20.04/ubuntu-20.04.3-live-server-amd64.iso

#get xorriso and compile
wget -nc https://www.gnu.org/software/xorriso/xorriso-1.5.4.pl02.tar.gz
tar xzf xorriso-1.5.4.pl02.tar.gz
cd xorriso-1.5.4
./configure --prefix=/usr
make -j
mv xorriso/xorriso /tmp/
cd /tmp

#extract ubuntu iso
./xorriso -osirrox on -indev ubuntu-20.04.3-live-server-amd64.iso -extract / ubuntu && chmod -R +w ubuntu
cd ubuntu
mkdir nocloud
cd nocloud

#copy user-data and change grub
touch meta-data
cp $intial_directory/autoinstall user-data

cd /tmp
sed -i 's|---|autoinstall ds=nocloud\\\;s=/cdrom/nocloud/ ---|g' ubuntu/boot/grub/grub.cfg
sed -i 's|---|autoinstall ds=nocloud;s=/cdrom/nocloud/ ---|g' ubuntu/isolinux/txt.cfg

# Disable mandatory md5 checksum on boot:
md5sum ubuntu/.disk/info > ubuntu/md5sum.txt
sed -i 's|iso/|./|g' ubuntu/md5sum.txt

#Recreate new install iso
./xorriso -as mkisofs -r \
  -V Ubuntu\ custom\ amd64 \
  -o ubuntu.iso \
  -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot \
  -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
  -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
  ubuntu/boot ubuntu

# Create vm with 8gb of ram
VBoxManage createvm --name FEUPVM --ostype Ubuntu_64 --register --basefolder /tmp/vm
VBoxManage modifyvm FEUPVM --cpus $cpu --memory $ram --vram 255

VBoxManage modifyvm FEUPVM --nic1 nat

VBoxManage createhd --filename /tmp/vm/FEUPVM.vdi --size 12024 --variant Standard

VBoxManage storagectl FEUPVM --name "SATA Controller" --add sata --bootable on

VBoxManage storageattach FEUPVM --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium /tmp/vm/FEUPVM.vdi

VBoxManage storagectl FEUPVM --name "IDE Controller" --add ide

VBoxManage storageattach FEUPVM --storagectl "IDE Controller" --port 0  --device 0 --type dvddrive --medium /tmp/ubuntu.iso

VBoxManage startvm FEUPVM
