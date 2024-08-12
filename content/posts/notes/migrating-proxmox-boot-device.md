---

title: "Migrating Proxmox Boot Device"
date: 2023-12-02T12:06:48+08:00
author: John Wu
description: "Notes on my migration of bootdrives on my Proxmox server"
tags: ['tech']
toc: true
draft: false

---

My current boot drive for proxmox is a single NVMe M.2 512GB device using the ext4 with LVM filesystem.
The problem with this are:
1. It is not redundant
2. It is not enough to store a git server on
3. It's boring
So, I will document my process in replacing this boot drive with x2 1TB NVMe drives.

# Plan

## Hardware
For the new boot drives, I'm going to use two [P5 Plus 1TB drives](https://www.crucial.com/ssd/p5-plus/CT1000P5PSSD8).

## Plan B
In case things go wrong, I need a plan B first.
All of my LXC and VM data are stored in my current ZFS under TrueNAS, so I can recover all of that if necessary.
The backups for Proxmox are under /etc/pve, and the manually configured files I have are only in /etc/nut.

My first step is to save everything in /etc/pve and /etc/nut into an external hard drive.
Then, I can begin the process.

## Actual Plan
1. Back everything up
2. Create a proxmox bootable USB
3. Shutdown proxmox and replace current boot drive with the new drives
4. Power on the machine and boot into the USB
5. Reinstall proxmox using ZFS RAIDZ1 between the 2 new 1TB NVMe drives
6. OPTIONAL: Cross fingers and pray
7. Update and reboot
8. Delete /etc/pve and /etc/nut on the newly installed machine, replace with the old directories
9. Recreate users from before reinstallation if needed
10. Restore to previous state

# Backing Up Everything
- Backed up proxmox LXCs and VMs
- Snapshotted ZFS filesystem
- Saved /etc/pve /etc/nut onto USB

# Create a Proxmox bootable USB
- This part is pretty easy
- Visit https://proxmox.com/en/downloads and download the latest proxmox version
- Since I'm on Arch linux btw, I use `sudo dd bs=1M conv=fdatasync if=./proxmox-ve_8.1-1.iso of=/dev/sdb status=progress`
    - NOTE: Change the name of the iso
- Once that's done, unplug the USB

# Shutdown PVE and Replace Current Boot Drive With New Drives
- Shutdown proxmox
- Open up the server and replace the boot drive

# Reinstalling PVE
- Boot into the BIOs and select the USB as the primary boot drive

## Installation Hiccups
Since I had a GT720, Xorg couldn't render the GUI installer.
To remedy this, I had to press 'e' in GRUB and add `nomodeset` to the end of the line starting with the word `Linux`.
Finally, boot into the terminal UI version of the installer.
The only downside is that you won't be able to use your mouse.

- In the installer, select ZFS RAID1
- Deselect all the drives that will not be used for boot
- Leave everything default
- Press next and continue installation

# Recover From Backup
- Once PVE has rebooted from installation, log in to the webUI
- Update and upgrade PVE, then reboot if there is a new kernel
- Change your repositories using [this article](https://pve.proxmox.com/wiki/Package_Repositories)
- Install nut `apt install nut`
- Plug in the USB with the backup of /etc/pve and /etc/nut
- Mount the drives to /mnt: `mkdir /mnt/usb ; mount /dev/USB_LABEL /mnt/usb`
- Do a simple `cp -r /mnt/usb/nut /etc ; cp -r /mnt/usb/pve /etc/pve`

# Restore Users and Storage Devices
- If you had any users outside of root from before, they would not "exist" on the new server even if they appear on the GUI
- You need to go into the PVE shell and create the user from the shell
```sh
useradd -m -s /usr/bin/bash username
passwd username
```

- For storage devices, add directories under "Datacenter" in the GUI
- The directories should point to your new ZFS paths

# Restore to Previous State
If your VMs had NFS or SMB shares before, you need to change the IP of your NAS (or not, if it's the same configuration).

If your backups were stored on another path, change them to new ones.

# Finish
You have migrated PVE to ZFS, nice.
