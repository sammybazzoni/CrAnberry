#!/bin/bash

if [ "$(id -u)" != '0' ]; then
    echo "Run this script as root! Use: sudo bash script.sh"
    exit 1
fi

android_vm_dir="/opt/google/vms/android"
wdir="/usr/local/cranberry_vm"

# Clean up mounts safely if they are still attached
if mountpoint -q "$wdir/new"; then
    echo "Unmounting active workspace copy..."
    umount -l "$wdir/new"
fi

if mountpoint -q "$wdir/original"; then
    echo "Unmounting original copy..."
    umount -l "$wdir/original"
fi

# Check for the ARCVM backup image
if [ -e "$android_vm_dir/system.original.img" ]; then
    echo "Restoring original ARCVM system image..."
    rm -f "$android_vm_dir/system.raw.img"
    mv "$android_vm_dir/system.original.img" "$android_vm_dir/system.raw.img"
    chmod 0644 "$android_vm_dir/system.raw.img"
    
    # Clean up SELinux policy backups if present (ARCVM specific paths vary by ChromeOS build)
    if [ -e /etc/selinux/arc/policy/policy.30.bak ]; then
        cp /etc/selinux/arc/policy/policy.30.bak /etc/selinux/arc/policy/policy.30
        rm /etc/selinux/arc/policy/policy.30.bak
    fi

    echo "Cleaning workspace files..."
    rm -rf /usr/local/bak
    rm -rf "$wdir"
    rm -f /usr/local/bin/busybox
    rm -f /etc/init/unforce.conf
    
    echo "Revert complete! Please reboot your Chromebook for changes to take effect."
else
    echo "Original ARCVM backup image not found. Cleaning up workspace directories anyway..."
    rm -rf /usr/local/bak
    rm -rf "$wdir"
    rm -f /usr/local/bin/busybox
    rm -f /etc/init/unforce.conf
    echo "Cleanup finished."
fi
