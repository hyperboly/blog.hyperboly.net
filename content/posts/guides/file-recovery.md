---

title: "File Recovery"
date: 2023-06-03T17:13:45+08:00
author: John Wu
summary: "Recovering and securely wiping disks"
tags: ['guides', 'tech']
ShowToc: true
draft: false

---

## Guide on File Recovery
Recently I've been drafted into a science fair for our school, so here's our project. It's an experiment on file recovery. The goal was originally to see how to fully destroy a file. We achieved this on the first day with the command `shred`. Here's Luke Smith to explain it ([video](https://www.youtube.com/watch?v=0WcrgvhO_mw)).

## Formatting NTFS, EXT4, and FAT32
Since we are testing this on a USB to not destroy all the data on my actual drive while testing, we need to wipe the USB first and start over with different filesystem types. This is just for testing different FSes.
```
mkfs.ntfs /dev/sda
```

```
mkfs.ext4 /dev/sda
```

```
mkfs.fat -F32 /dev/sda
```

## Mounting The Drive
Now, we need to mount the drives, create and delete a few files for testing.

`/dev/sda` is the drive name
`/mnt` is the mountpoint

1. For NTFS filesystems
```
mount -t ntfs /dev/sda /mnt
```

2. For EXT4 filesystems
```
mount -t ext4 /dev/sda /mnt
```

3. For FAT filesystems
```
mount -t vfat /dev/sda /mnt
```

Navigate to `/mnt` and there should be no output when you try `ls`. Or, it would just be something like a `System Volume Information` directory thats hard coded into the USB.
Create a few files and write something or download binaries into it.
```bash
echo "This is a cool test" > testfile.txt
echo "# This _is_ another cool text file in **markdown**" > testfile2.md
wget https://larbs.xyz/pix/larbs.png
mkdir testdir
touch testdir/dirTestFile

# Now to back out and unmount
cd ~
sudo umount /mnt
```

## Using `testdisk`
Testdisk is the program that I used to recover deleted data.
Using testdisk is as simple as scrambling an egg. Throw it in the pan and figure out the correct timing to flip it, do it enough times and you get good at it.
First, install it and open it up with root privs.
```
sudo testdisk
```

In the testdisk menu, create a new log and click through.
Select the partition or drive you want to look through, which can be checked with `lsblk -f`. In my case the output was this.
```
NAME FSTYPE FSVER LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
sda  ext4   1.0         4d856ebd-8184-4c22-88a7-807ae7d99d02                
nvme0n1
                                                                            
├─nvme0n1p1
│    vfat   FAT32 EFI   E540-2563                             401.8M    21% /boot
└─nvme0n1p2
     crypto 2           67f9b13a-dc2d-4bdc-ad4c-113f335b6ea8                
  └─luks
     btrfs        ROOT  eb473c57-683a-40ce-95a5-1c70c206cfe5  397.8G    16% /home
                                                                            /btrfs
                                                                            /.snapshots
                                                                            /
```
As you can see, `sda` is my USB and `nvme0n1` is my main drive.
So in my case, I should select `/dev/sda`. `/dev` meaning devices.

It should select the correct partitioning table format by default for you so you don't have to choose.
If you made the filesystem yourself, it should be none because I didn't partition it.

Select the "Advanced" option into the drive.
Now select the "List" tab.
You can now look through the different directories in the USB and see which files were deleted which ones weren't.
Select the ones you want to recover by following the instructions at the bottom of testdisk and copy it to your local drive.

## Permission Issues
If your user is not already root, `sudo testdisk` may output files with root perms.
To check for permissions:
```
ls -l /mount/point
```

To change permissions to current user:
```bash
id # check for UID and GID
chown 1000:1000 /path/to/file # 1000:1000 is the UID:GID
# Now you can open the file with user perms
```

## Did It Work?
Checking to see if you actually got the contents of the files.
```
cd /path/to/recovered/files
cat testfile.txt
cat testfile2.md
swayimg larbs.png # Since I use wayland now, this is my image viewer. Use your own image viewer.
cat testDirFile
```

## *Nuances*
I used a big word! Do you think I'm smart now???

In my tests, I did not test for btrfs, zfs, or any of the enterprise level filesystems because I did not have redundant drives nor the motivation to format my USB with btrfs/zfs, create different snapshots & mountpoints just to simulate real world enterprise NAS systems.

I also did not test for any encrypted systems. The Luke Smith video linked above would show that encrypted systems will still leak metadata though.

Basic file recovery could be done on simple partition schemes such as desktop Windows and desktop Linux as shown in this article really easily. For Mac file recovery, take a sledgehammer and slam it onto the disk, that way you'll get a real device.

## How It Works (Boring)
When you do something like use the `rm` command or flush your recycle bin, you destroy the pointer on the physical drive to the deleted file's physical location.

The filesystems I worked with are separated in blocks and sectors.
Sectors are the minimum storage size that a storage device (USB, HDD, SSD, NVMe) can hold. This is normally 4096 in my experience.
Blocks are the logical (software) abstraction of sectors.

### Disecting The Block
Everything below will be for the ext4 filesystem.
There are many aspects to a block, including block groups, inodes, and super blocks.
Before I said that when you remove a file, you are removing a pointer.
Under ext4, that pointer is setting a block as "used" or "unused."

A block normally contains more that 1 sector, which means the operating system could write much faster because it doesn't need to process every sector.
An inode is always paired with a block, or set of blocks.
Inodes are where metadata about the file is stored, this metadata can include information on the links, number of blocks allocated to a file, permissions...

A block group structure looks like this:
```markdown
Block Group 1
|
+--Super Block
|  contains information about all the metadata including: total block count, total inode count, blocks per group...
|
+--Group Descripters
|  Stores information on locations of different information that is too complicated for now
|  (Lower 32-bits of location of block bitmap, lower 32-bits of location of inode bitmap).
|
+--Inode Bitmap
|  Tracks usage of inodes
|
+--Block Bitmap
|  Tracks usage of blocks
|
+--Inode Table
|  Defines the relation of files and their inodes. 
|
+--Data Blocks
|  Where file content is stored. The important stuff
```

## Recovering Files
Now you're a block expert, so what?

When the inodes and blocks are removed from the logical block groups, it is removed from your operating system.
Try going into your file browser and remove a file, can you see it? No. Because you deleted it, bozo move.
The PHYSICAL locations, or sectors, still contain your data though.
You didn't wipe the data blocks, you removed it from the inode bitmap and block bitmap (and inode table).
So, all you have to do is recover those sectors.
Well thank god we have tools like testdisk that can do it automatically for us.

# SHRED EVERYTHING
Now that you know how file recovery works, it's time to counter it.
You can't have the feds looking into the precious cat videos that were too dangerous so you deleted the files.

The true way to delete something is to overwrite it with something else.
When the actual data is overwritten with something else, then the original data becomes the new data.
There are many ways to do it, but the easiest way is the `shred` command.
If you have a very dangerous file, go ahead and just shred it.
```bash
shred /path/to/file
```
Simple!

There are many other things you can do to shred your data, but Luke Smith already covers it in his [video](https://www.youtube.com/watch?v=0WcrgvhO_mw).

# Sources
[Normie article, basic ideas](https://www.freecodecamp.org/news/file-systems-architecture-explained/)

[Real docs from Linux about ext4](https://ext4.wiki.kernel.org/index.php/Ext4_Disk_Layout#The_Super_Block)

[inode wiki article](https://en.wikipedia.org/wiki/Inode#Multi-named_files_and_hard_links)
