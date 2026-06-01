#!/bin/bash

if [ "$(id -u)" != '0' ]; then
    echo "Run this script as root! Use: sudo bash script.sh"
    exit 1
fi

wdir="/usr/local/cranberry_vm"
# Updated paths for ARCVM
android_vm_dir="/opt/google/vms/android"
device_arch=$(uname -m)

# Clean up from a previous attempt if applicable
touch /etc/cranberry-test
sleep 0.5

if [ ! -e "/etc/cranberry-test" ]; then
    echo "Your rootfs doesn't seem to be writable. Make sure you run:"
    echo "sudo /usr/share/vboot/bin/make_dev_ssd.sh --remove_rootfs_verification --partitions 2"
    echo "and reboot before you run this script."
    exit 1
fi
rm /etc/cranberry-test

# Check for ARCVM image path instead of ARC++ container path
if [ ! -d "$android_vm_dir" ]; then
    echo "ARCVM directory not found at $android_vm_dir. Is ARCVM installed?"
    exit 1
fi

if [ ! -e "$android_vm_dir/system.raw.img" ]; then
    echo "No android system image present in $android_vm_dir"
    exit 1
fi

# Remount /usr/local to allow execution
mount -o remount,rw,exec /usr/local
sleep 1

# Setup workspace
if [ -e $wdir ]; then
    umount $wdir/original 2>/dev/null
    umount $wdir/new 2>/dev/null
    rm -rf $wdir
fi

mkdir -p $wdir/original
mkdir -p $wdir/new

# Backup original image if not done already
if [ ! -e "$android_vm_dir/system.original.img" ]; then
    echo "Backing up system.raw.img..."
    cp "$android_vm_dir/system.raw.img" "$android_vm_dir/system.original.img"
fi

# Create a larger workspace image to hold Android 13 + Root binaries
dd if=/dev/zero of=$wdir/arcvm_new.img bs=1 count=0 seek=3500M
mkfs.ext4 -F $wdir/arcvm_new.img

# Mount images
mount -o loop,ro "$android_vm_dir/system.original.img" $wdir/original
mount -o loop,rw,sync $wdir/arcvm_new.img $wdir/new

echo "Copying Android 13 files to workspace..."
cp -a $wdir/original/. $wdir/new/
sync
umount $wdir/original

# Disable SELinux enforcement for root access verification
setenforce 0
echo "SELinux forced to Permissive for injection."

# WARNING: Android 13 requires Magisk init injection. 
# Traditional SuperSU binary copying to /system/xbin/su WILL NOT WORK.
echo "--------------------------------------------------------"
echo "System files copied successfully to workspace image."
echo "ARCVM Android 13 requires Magisk injection into ramdisk."
echo "Please look into MagiskOnChromebook scripts to patch init."
echo "--------------------------------------------------------"

# Finalizing image replacement
echo "Replacing active ARCVM system image..."
umount $wdir/new
mv $wdir/arcvm_new.img "$android_vm_dir/system.raw.img"
chmod 0644 "$android_vm_dir/system.raw.img"

echo "Done. Please restart the Subsystem or reboot your Chromebook."
