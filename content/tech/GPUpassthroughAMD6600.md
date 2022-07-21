---
title: "GPU passthrough for RX6600XT"
date: 2022-06-07T18:09:07+08:00
author: John Wu
draft: false
---

# A Comprehensive Guide on GPU Passthroughs in Proxmox

## Some Prerequisites and Notes

This method of passing through my GPU works for:
- Kernel: 5.15.30
- Proxmox Version 7.2
- TUF Gaming X570 Plus Motherboard
- Dual Radeon RX6600XT Asus GPU
- Ryzen 7 5800X CPU

In the BIOs for your host computer (where Proxmox is installed) settings, these options should be modified:
- Secure boot: Off
- CPU Settings:
	- SUM: On
	- PSS: On
- PCI Subsystem Settings:
	- Above 4G Encoding: On
	- SR-IOV Support: On
- AMD CBS:
	- IOMMU: On

## The Passthrough Process

This is the part of the process where everything is either done in an ssh session, on the host computer's shell, or the webGUI for proxmox.

### Update Proxmox
First make sure your Proxmox is updated with the correct repos. You can follow the [Proxmox docs](https://pve.proxmox.com/wiki/Package_Repositories#sysadmin_no_subscription_repo) for this.

Next, you want to get your favorite text editor (Nano is preinstalled but I will use vim)

> ``$ apt-get install vim``

### GRUB/Systemd Edits

For Systemd, every step will be the same, the only difference is you will edit `/etc/kernel/cmdline` for the GRUB flags, all flags will be the same.

``$ vim /etc/default/grub`` to get edit a file. I assume you have background knowledge already in a terminal, if not, refer to vim(1) or nano(1).

Find the line ``GRUB_CMDLINE_LINUX_DEFAULT = "quiet"`` and add these flags within the quotation marks:
> ``iommu=pt amd_iommu=on video=efifb:off video=vesafb:off textonly video=simplefb:off nofb``

Write quit.

> ``update-grub``
update-grub works even if you are on systemd boot.

After this, reboot.

### Messing With Drivers

Check if you did everything correctly with

> ``dmesg | grep -e DMAR -e IOMMU``

This should output something along the lines of "IOMMU enabled" or something like it.

You can also check with  
> ``cat /proc/cmdline``

This should output what you modified in GRUB or systemd boot.

Now you want to edit the ``/etc/modprobe.d/blacklist.conf`` file in order to blacklist your host machine from using your GPU so that the GPU isn't split between your host and VM (splitting the processes will break it). Add these lines:  
> ``blacklist nvidia``  
``blacklist nouveau``  
``blacklist radeon``

Now edit the ``/etc/modules`` file and add:  
> ``vfio``  
``vfio_iommu_type1``  
``vfio_pci``  
``vfio_virqfd``

Now you update initramfs and reboot with:  
> ``update-initramfs -u``  
``reboot``

### Isolating Your GPU

Run ``lspci -nnk`` and find your GPU. My RX6600XT GPU shows up as:  
> __0a:00.0__ VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Navi 23 __[1002:73ff]__ (rev c1)

Below it should be a audio controller. Mine looks like:  
> __0a:00.1__ Audio device [0403]: Advanced Micro Devices, Inc. [AMD/ATI] Device __[1002:ab28]__

Note the 0a:00 and [1002:XXXX], these will be important soon.

Now you will edit ``/etc/modprobe.d/vfio.conf`` and add:  
> ``options vfio-pci ids=XXXX:XXXX,XXXX:XXXX disable-vga=1``

Where XXXX:XXXX are substituted by the numbers in the [] before. For example, for me it would look like:  
> ``options vfio-pci ids=1002:73ff,1002:ab28 disable_vga=1``

Now reboot again just in case.

To check if you are using the correct kernel module for your GPU, do ``lspci -v`` and see if your GPU's kernel in use is vfio-pci or the line is just not there. If either is true, you're halfway there.

### Black Magic Section

Welcome to Black Magic, where nothing in the section makes sense to me.

Run ``cat /proc/iomem`` and under your GPU bus (0X:00, or for me it's 0a:00), there might be a BOOTFB. If you don't see BOOTFB, skip this section. If you do, follow the next steps carefully.

> ``cd /root``  
``touch gpufix.sh``  
``vim gpufix.sh``  

Inside this file, you will add these lines:  
> ``#!/bin/bash``  
``echo 1 > /sys/bus/pci/devices/0000:0X:00.0/remove``  
``echo 1 > /sys/bus/pci/rescan``

Write and quit. Run ``chmod +x gpufix.sh``. Lastly, add to the cron entry.

> ``crontab -e``  
``@reboot /root/gpufix.sh`` at the end of the file.

Reboot.

### VM Creation

If the settings are not mentioned in this segment, leave them as default. Go into the web GUI for Proxmox and click on create VM. I used a Windows 11 VM with VirtIO drivers (get the ISOs from [Windows officially](https://www.microsoft.com/software-download/windows11/) and [Redhat unofficially](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/?C=M;O=D)).  
The following segment are settings ___needed___ for this to work:
- System Settings:
	- q35
	- OVMF
	- EFI disk and TPM (note that EFI and TPM must be stored on the same disk)
- Disk Settings:
 	- SCSI
	- At least 50GB for Windows bloat
- CPU:
 	- As much as you can give it, for example 6 cores.
- RAM:
	- As much as you can give it, for example 8GiB.
- Networking:
	- Virt-IO (paravirtualized)
- Do not start after creation.

After you have created the VM, go into the hardware settings and add an ISO image. This ISO image would be the Virt-IO drivers that you downloaded before. In the options tab in the VM under hardware check the Boot Order. The Boot Order should be your 50GB (or what you set it) hard disk first, your Windows ISO (in ide), net0, and lastly the Virt-IO drivers (ide).

### Windows 11 Installation

First, be prepared for the pain and suffering Windows 11 installation can be. Linux is years ahead with the installation with the live USB thing, why can't Microsoft catch up? Anyways, you'll apply the virt-IO drivers here.

1. Click on install Windows and custom install.
2. You must select Windows 11 pro.
3. This will prompt you into a window where you can select Load Drivers.
4. In the file explorer, click on your C: or whatever drive that has the virt-IO drivers.
5. Drop down the amd64 folder and choose the w11 folder. Press OK and Next.
6. Load another driver called the NetKVM driver, choose NetKVM>w11>amd64.
7. Go through the rest of the install process reading what it prompts you to do. ___CAREFULLY READ THESE BECAUSE YOU CAN OPT OUT OF SPYWARE___... probably. 
8. After everything's settled and you can log into Windows, go to file explorer and select the virt-IO drive once more. Click on _virtio-win-gt-x64_ and execute it.
9. Shutdown the VM and go back to the Proxmox web GUI. Select hardware again and add a PCI device. Look for your 0X:00.0 vendor tag and select it. Tick every box except for primary GPU (PCI-express, ROM-Bar, All Functions). Start your VM up again.
9. Go into the browser and look for AMD GPU drivers, download it and install it.
10. While installing, you might notice your host machine's monitor start displaying Windows but your mouse and keyboard may not be able to do anything. Reboot and follow the next section.
11. Finally, tick the primary GPU option in your GPU options.

### Finishing Touches

By now, you are already set to go, except that you can't do anything with your keyboard and mouse. To fix this, shutdown the VM once more and go to hardware settings in the Proxmox web GUI. Add USB devices and passthrough every port with your keyboard, mouse, whatever else you want. Now, you are truly done. Start up your VM and enjoy being exploited by Windows.

## External Links

If you continue to struggle with GPU passthrough, here are all the articles I went through to find my solution.

1. #### Documentation

	1. [Proxmox Docs](https://pve.proxmox.com/wiki/Pci_passthrough)
	2. [Arch Wiki](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF)
	3. [Debian Docs](https://wiki.debian.org/AtiHowTo)

2. #### Unofficial Guides
	1. [Reddit Ultimate Guide (outdated)]( Passthroug://www.reddit.com/r/homelab/comments/b5xpua/the_ultimate_beginners_guide_to_gpu_passthrough/)
	2. [Reddit 2 Min Guide (outdated)](https://www.reddit.com/r/Proxmox/comments/lcnn5w/proxmox_pcie_passthrough_in_2_minutes/)
	3. [Tutorial From Proxmox Forums RX6600XT Specific (didn't work for me)](https://forum.proxmox.com/threads/gpu-passthrough-radeon-6800xt-and-beyond.86932/)
	4. [Dumping V-BIOs Blog](https://blog.quindorian.org/2018/03/building-a-2u-amd-ryzen-server-proxmox-gpu-passthrough.html/)

3. #### Forums
	1. [Black Magic](https://forum.proxmox.com/threads/problem-with-gpu-passthrough.55918/page-2)
	2. [Radeon RX6600 Specific Post on Reddit](https://www.reddit.com/r/VFIO/comments/p30r0c/6600xt_passthrough/)
	3. [Dumping V-BIOs Thread](https://forum.level1techs.com/t/replaced-radeon-pro-with-radeon-rx-6600xt-on-proxmox-and-now-getting-code43/180419)

## Support This Guide

If you have any other GPU's that you got working whether absurdly like me or even normally, consider making a pull request for it or submitting an issue on the [github](https://github.com/hyperboly/techsite)!
