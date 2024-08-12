---

title: "ZFS From CLI and ZFS File Recovery"
date: 2023-06-07T21:30:32+08:00
author: John Wu
description: "A continuation of file recovery, but with ZFS and some basic commands that I learned on the way [SPOILER: I FAILED]."
tags: ['guides', 'tech']
toc: true
draft: false

---

This is just to document what I'm learning about ZFS and how to control it/tame it from CLI.
This is a continuation of my [file recovery article](https://blog.hyperboly.net/posts/guides/file-recovery/) so I'm going to be testing for file recovery on ZFS as well.
Because I'm unfamiliar with ZFS CLI, I'll be documenting the CLI commands for my personal use later anyways.
Find installation instructions from the [arch wiki](https://wiki.archlinux.org/title/ZFS#Installation) or [debian instructions](https://openzfs.github.io/openzfs-docs/Getting%20Started/Debian/index.html#installation).

Note I'll be writing these notes while doing the actual testing, so bear with the troubleshooting.

# Creating a Pool
Make sure the drives you want to create a ZFS pool on is empty of any partitioning schemes first.
```bash
wipefs -a /dev/sdX
wipefs -a /dev/sdX
...
```

To create a pool, all you have to do is use `zpool`.
In my case, I needed `-f` for `--force` because I am using 2 different sized USBs as a test for RAIDZ1. Basically I get a redundant drive as a test. Don't do this with your USBs, it will wear them out fast especially if you're using it for production. Mine are almost dead or were for bootable Linux machines anyways.
```bash
zpool create -f pool1 raidz /dev/sdb /dev/sdc  # substitute raidz for whichever raidz configuration you want (raidz2|3). By default raidz is raid 5
zpool list # lists your pools
zfs list # lists your datasets within pools and gives you logical storage sizes
```

To create some datasets (logical storage volumes in ZFS), use the zfs command:
```bash
zfs create pool1/ds1
zfs create pool1/ds2
```

Now, you can start moving your storage around. Without caring about permissions, I did everything as root. If you want to be more secure than how I did it, use `chown`.
```bash
chown -Rfv $USER:$USER /pool1/dsX
```

# Setting Up Pool For Testing
Since I'm using this to test for file recovery, I'll put a few binaries and text files in to see what happens and then use testdisk to try and recover them.
```bash
cp -v /usr/bin/ls /pool1/ds1

echo "This is a test file" > testfile.txt
mv testfile.txt /pool1/ds1

echo "This is a test file for ds2" > testfile2.txt
mv testfile2 /pool1/ds2

cp -v /usr/bin/whoami /pool1/ds2
```

# Deleting Files and Initial Theories
I think that because ZFS has redundancy, what you do to the drive with the active data would get erased, but still recoverable from tools like testdisk.
I'm not sure if ZFS uses a git-like thing where you can just reset back to a previous save.
From what I understand, ZFS is not built to recover deleted files, but to prevent FS corruption from dead drives.
So how easy would it to recover a file from:

1. A deleted file on a not-deleted dataset
2. A deleted dataset and all it's files

And, is it possible to recover them from the individual drives.
In my head this all works because ZFS is a copy on write FS, so anything written on sdb should be written to sdc.

Time to test this.

Deleting some files from ds1
```bash
rm /pool1/ds1/testfile.txt
rm /pool1/ds1/ls

touch /pool1/ds1/control # control file to differentiate between not-deleted and deleted files later. Avoiding confusion (maybe, just pray)
```

Deleting the whole second dataset `ds2`:
```bash
zfs list # make sure I'm deleting the right one
zfs destroy pool1/ds2
zfs list # make sure it's gone
```

Now I'll shutdown the VM and test individual drives on my laptop. Bravo 6, going dark.

# File Recovery
The process for ZFS was much harder and takes longer than for ext4. No wonder professionals get paid so much.

Using `testdisk` to analyze the ZFS pool, the tool under the "Advanced" tab does not allow you to use "Undelete" unlike ext4.
I think this is because there's no Superblock in ZFS implementations, so I can't just immediately locate files.
Although ZFS has uberblocks, which should behave similarly? Not sure.

Using testdisk on the drive did not work, so I have created a `dd` image of the whole drive with:
```bash
dd if=/dev/sdb of=/mnt/rec/smi # rec is recovery, smi is the brand of my USB. Weird naming scheme I don't care
```

Running a grep on the new image returns this:
```bash
~/testdisk > strings image.dd | grep ls
...
# LS_COLORS environment variable used by GNU ls with the --color option.
# One can use codes for 256 or more colors supported by modern terminals.
# List any file extensions like '.gz' or '.tar' that you would like ls
src/ls.c
GNU coreutils
  -f                         do not sort, enable -aU, disable -ls --color
                               used only with -s and per directory totals
                               unless program is 'ls' and output is a terminal)
Also the TIME_STYLE environment variable sets the default style to use.
with --color=never.  With --color=auto, ls emits color codes only when
https://www.gnu.org/software/coreutils/
or available locally via: info '(coreutils) %s%s'
bug-coreutils@gnu.org
/usr/lib/debug/.dwz/x86_64-linux-gnu/coreutils.debug
...
```

This confirms to me that `ls` STILL exists, but I'm just not smart enough to recover it.
ZFS recovery just got 10x harder.

ZFS recovery has a time limit.
Normally, you only have 15-20 minutes to recover because of how ZFS works (not sure why).
Thankfully, I had `dd`ed the device in time to have it contain all the files.
I have exported the zpool with:
```bash
zpool export /dev/sdb1
```

After exporting, I ran `zdb -ul /dev/sdb1` to find the uberblocks (superblocks in German).
This gives me a general idea of when uberblocks were created and the specific timing.
I have no clue which second I deleted the different files.

## Luck Based Recovery
Are you a gambler? Are you in need of recovering your ZFS pool because you didn't set snapshots and backups??? Perfect!
Let's recover a snapshot from the uberblocks using `zdb`.

```bash
zdb -ul /dev/sdb1
```
This command should have outputted all the information about the uberblocks and it's timestamps of where you can teleport to back in time.
So select one you think is the most likely and try it with this.

```bash
zdb -F -T <transaction_id> <pool_name>
```

In my case, the only output was this:
```
cannot import 'pool1': I/0 error
```

In the end, after 5 hours of effort, I had failed.

# Reflection
I didn't expect ZFS file recovery to be this difficult, I thought I could pull up photorec or testdisk, run it a few times, mess around with the UI and it'll work.
Unfortunately, it's not that easy and ZFS is a file system that requires a lot more work than that.
ZFS is not built to have files recovered like this, it's built to provide redundancy.
If drives fail past your RAID configuration, you're done. You'll have to go through what I did tonight.

The moral of this is to make sure you always backup your data following the 3-2-1 backup rule if you can, take regular snapshots (even every 30 mins and last each snapshot for 24-26 hours), and if it ain't broke; don't fix it.
I'm definitely increasing how many snapshots I take per hour after this.
If you are a normal consoomer, backup to the cloud (PLEASE ENCRYPT YOUR STUFF BEFORE YOU SEND IT).
If you have your own server, hope this is educational.

# Final Theory
There is still a way I can think of recovering those files.
When I grepped the `dd`ed image of the filesystem, I could see my `/usr/bin/ls` file still existing in the image.
If you know EXACTLY what you're looking for, like file types (docx, png, jpg), you can write a script that goes through the hex looking for specific hex patterns and extracting them out.
Then, reassemble when you are done with extraction.
Due to my timeframe and skill, I can't do this myself and so I won't.

Anyways, hope this helped.

# Resources Used
[Reddit thread on the last bit with zdb](https://www.reddit.com/r/zfs/comments/478wwd/comment/d0b73db/?utm_source=share&utm_medium=android_app&utm_name=androidcss&utm_term=1&utm_content=share_button)
