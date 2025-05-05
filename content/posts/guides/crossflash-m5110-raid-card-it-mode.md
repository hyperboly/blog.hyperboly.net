---

title: "Crossflash M5110 Raid Card It Mode"
date: 2025-04-29T18:01:06+08:00
author: John Wu
description:
tags: ['tech', 'guides']
description: "A guide on crossflashing the M5110 (LSI 9240-8i) to IT mode"
toc: true
draft: false

---

This weekend I got a second hand Dell Precisiion Tower that enterprise used as a server, inside included an IBM ServeRAID M5110 RAID card that wasn't in RAID mode.
Since I need ZFS and don't like what I hear about harwdware RAID, it needed to be flashed to IT mode.
IT mode is basically passthrough mode and becomes dumber than the RAID mode, since it doesn't do any redundancy (that's handled by ZFS in the operating system).

Unfortunately, the M5110 by default does not support IT mode so I need to flash another cards firmware onto it.
Very very fortunately, someone has already done it and given a very well designed guide.

[Link](https://lazymocha.com/blog/2020/06/05/cross-flash-ibm-servraid-m5110-and-h1110-to-it-hba-mode/)

This was my first time flashing firmware to a card following a guide that assumed you had prerequisite knowledge of flashing firmware.
Sadly, I don't know how to read so it took a while to get it working.
Thus, I thought I'll write my own blog on how to do this if anyone needs it.

# What You'll Need
1. A normal windows installation
1. A spare USB you don't mind wiping
2. Some pliers
3. The number at the back of the card that should start with "5006XXX XXXXXXXX"
4. The M5110 firmware pack that is included in lazymocha's tutorial. Here is the [link](https://web.archive.org/web/20200605095944/https://lazymocha.com/test/M5110-firmware.zip) and an alternative [link](/files/M5110-firmware.zip).

# Cross Flash the Card
1. The first thing you'll do while you have the card out and checking it's serial (the number that starts with 5006...), is to remove the alarm.
![image of the alarm](/images/guides/m5110-alarm.png)
Use the pliers mentioned in the [what you'll need](/posts/guides/crossflash-m5110-raid-card-it-mode/#what-youll-need) section to **crush** the plastic, not pull.
Once crushed, you'll see a red muzzle where you'll have to try your best to pull it off without damaging the card.
2. Plug in the card but don't connect any cables to it.
Also plug in the USB while you're at it.
3. Boot into Windows first
4. Install rufus, have it select your USB and under "Boot Selection" select "FreeDOS."
No need to download an ISO file or anything, rufus already has it handled.
5. Download and unzip the `M5110-firmware.zip` file found in this section: [what you'll need](/posts/guides/crossflash-m5110-raid-card-it-mode/#what-youll-need).
6. Copy the directory over to the new FreeDOS bootable USB.
You can put it in the root directory, or anywhere else (root meaning something like `D:\` not `D:\locale`)
7. You'll need to create EFI files for when we need EFI.

From lazymocha:
>  Create UEFI Bootable USB:
>
>  Create the folders boot\efi and efi\boot on USB drive.
>
>  Copy the file Shell_full.efi to both folders and to the root folder of the USB drive, and rename it to BootX64.efi
>
>  Copy the file Shell_full.efi to both folders and the root folder, and rename it to ShellX64.efi
>
>  When you’re done, you will have the same file to the USB drive 6 times, in 3 folders, named both BootX64.efi and ShellX64.efi

8. Reboot and enter the BIOs to choose booting in "Legacy" or you might see "BIOs" mode.
9. Once BIOs mode selected, exiting the BIOs should boot you right into FreeDOS unless you have another disk that is legacy bootable.
10. Once in DOS, you'll see a screen that mentions <CTRL><H> to enter WebBIOs or <CTRL><Y> for Preboot CLI.
Ignore this screen and wait for the screen where you see the prompt `C:\`
11. From here, you'll want to enter the `M5110-firmware` directory you copied into the root of this USB so enter:
```cmd
dir
```
to check where the directory is change directory into it:
```cmd
cd M5110-firmware
```
12. Once in, now you can start entering commands from lazymocha:
>`megarec -adplist` (note the adapter number, assuming it is 0)
>
>`sas2flsh -list` (note the SAS address) this command won't work right now
>
>`megarec -readsbr 0 m5110.sbr` (backup SBR)
>
>`megarec -cleanflash 0`
>
>soft reboot to FreeDOS, this is CTRL+ALT+DEL
>
>`megarec -m0flash 0 2208_16.rom` (flash recovery firmware)
>
>soft reboot to FreeDOS, this is CTRL+ALT+DEL
>
>`megarec -writesbr 0 512byte.bin` (wipe old SBR with empty)
>
>`megarec -cleanflash 0`

13. Finally, reboot to the BIOs again and change the mode from legacy back to UEFI.
Change boot order to your USB stick first and exit the BIOs to enter the UEFI shell.
14. Once in the UEFI shell, you want to cycle from `fs0:` to `fs5:`, if you still can't find where the files are I can't really help ya.
To cycle between them, just type `fsX:` from the shell.
To see if your files are there, just type `ls` or `dir`.
15. Find your `M5110-firmware` directory and `cd` into it.
16. Now you can finally run the `sas2flash.efi` commands.

From lazymocha:
> `sas2flash.efi -list` (adapter should be listed)
>
> `sas2flash.efi -o -f 20.00.02.00_07_it.fw -b bios_07.39.00.00.rom` (cross-flash with 2308 IT rom and BIOS)
>
> `sas2flash.efi -o -b uefi_07.27.04.00.rom` (cross-flash with 2308 UEFI BIOS)
>
> `sas2flash.efi -list` (adapter should be updated to SAS 2308)
>
> `sas2flash.efi -o -sasadd 5006xxxxxxxxxxxx` (re-program SAS address)

17. Check if everything works with the `sas2flash.efi` diagnosis: `sas2flash.efi -list`.
If Firmware Product ID says `(IT)` then you're good.
18. For the last time, reboot and go into Linux or back to Windows.

# Good luck!

# Thanks To
[lazymocha](https://lazymocha.com/blog/2020/06/05/cross-flash-ibm-servraid-m5110-and-h1110-to-it-hba-mode/): For the guide and files.

[kyletsenior](https://forums.servethehome.com/index.php?threads/some-additions-to-the-m5110-it-mode-flash-guide.39649/): For the extra information on lazymocha's guide.

[blanchet](https://www.truenas.com/community/threads/checking-if-my-lsi-hba-is-in-it-mode.92164/): For explaining how to check if the card is in RAID or IT mode.

[sergei](https://sergei.nz/cross-flash-m10159420-8i-lsi-controller-quasi-official-way/): For explaining the flashing process so that a Linux user can understand better.

^ the links above are all blog pages and forums that I found helpful.
