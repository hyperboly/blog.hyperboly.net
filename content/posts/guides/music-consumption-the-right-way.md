---

title: "Music Consumption the Right Way"
date: 2023-03-24T21:21:08+08:00
author: John Wu
summary: "Learn how I get adless, downloaded, high enough quality music all for free."
TocShow: true
tags: ["guides", "tech"]
draft: false

---

I got tired of Spotify stealing my information, showing me ads, and draining my mobile data usage. So I downloaded free music from Youtube.

## Tools
### Downloading Music
`yt-dlp`:
- A fork of `youtube-dl`, but uses aria2 and bypasses a lot of DRM, and is generally better I think
- Will be used for downloading songs, playlists...
### Syncing Music
`syncthing`:
- One of the greatest tool for syncthing files, not just music
- Easy webUI, configuration, and usage
- Very similar to rsync except it doesn't use `ssh` and is more "user friendly" if you don't like CLI

## `yt-dlp`
### Manual Usage
You can manually download videos/audio from Youtube just with yt-dlp alone. The most basic usage is `yt-dlp "https://youtube.com/watch?=v..."`, which will download the video and audio in the default formats and quality.

This is not what you're here for though, you want to know how to use this tool like an ultra chad music listener, so here is the command:
```bash
yt-dlp  -x --audio-format opus --add-metadata --metadata-from-title "%(title)s" -o "%(title)s.%(ext)s" "https://www.youtube.com/playlist?list=PLBVTuiShXIE7sDtTKaW4CygVLUEv7zNv2"
```
It's definitely not pretty, so let's go through each argument (also see `man yt-dlp`)
- `yt-dlp`: the tool we're using, argument for stdin
- `-x`: specifying we want to extract audio
- `--audio-format opus`: defines what kind of audio format we want. I am using \*.opus here even though it's not the best quality. To get the best quality, replace `-x --audio-format opus` with `-f bestaudio`
- `--add-metadata`: specifying we want to have metadata like date published, album...
- `--metadata-from-title "%(title)s"`: specifies that we want to extract the metadata from the title, not somewhere else (like when I accessed the video). %(title)s ist just saying have the download file have metadata from the video
- `-o "%(title)s.%(ext)s"`: specifying output file name. Or, what the download file name will be called. In this case, the title string with the file extension (specified as opus from `-x --audio-format`)
- The youtube link is my own playlist, you can replace it with your own. Just make sure it's in quotes "".

### My Script
The manual way definitely works, but it's slow; plus, you have to redownload your playlist again if you want to add more songs to your playlist.
Introducing my script `ytpl-update`, found [here](https://github.com/hyperboly/dotfiles/blob/main/.local/bin/ytpl-update).
This script only works on linux, but you can probably use wsl2 and it will work. The script checks if you have yt-dlp installed to the latest version, asks for where you want to download the music, and asks for your music playlist link before downloading the playlist. When you use this script, it creates a file that keeps track of **only songs that were explicitly downloaded**, and will check the file to know if a song needs to be updated. So when you download your whole playlist, add a few songs to it, the script will not redownload your whole playlist again.

#### Usage
Because this script was not designed with the UNIX philosophy in mind and more "user friendly," there are no supported arguments. I may add them in the future.
I will run through a basic example of how to use it, although the prompts should make it clear already.

```bash
# copy the code or clone the repo

chmod +x ytpl-update

./ytpl-update # run the script

# ytpl-update will check if you have the latest version of yt-dlp installed and attempt to update if there is. Will also attempt to install if not already installed

Which directory would you like to download to (Ex. ~/Music/example)? # Enter in the folder you want to download to
~/Music/all-my-songs

Insert playlist URL you would like to download/update # Do not add quotes, just the URL will work
%(title)s.%(ext)s" "https://www.youtube.com/playlist?list=PLBVTuiShXIE7sDtTKaW4CygVLUEv7zNv2

Downloading music from remote, please make sure test is the correct directory
Continue?  [y/n]: # will only take "y" or "n" as input. "y" is yes and "n" is no
y

# Downloading will start now, wait until the download process is finished and you are gold
```

## Syncthing
How will I get all this music from my Linux laptop to my phone? How will the files be automatically synced together when I add or delete files?
Syncthing. The answer is always syncthing.

### Installation
For Windows: https://docs.syncthing.net/intro/getting-started.html
For Linux: https://apt.syncthing.net/ (unfortunately I can only find installation for apt, arch, and nix. Fedora users you are alone, sorry)
For android: https://play.google.com/store/apps/details?id=com.github.catfriend1.syncthingandroid
Sorry no iOS, not really sorry. You shouldn't be using Apple products anyways

Now it's just a matter of linking your devices together to recognize each other and share the device over. This process is simple.

### Connect Your Devices

#### On Linux
Once installed from Ubuntu or Debian, the daemon should be already created.
```bash
systemctl --user enable --now syncthing.service
```
This will enable sycnthing at startup and you can go to [http://127.0.0.1:8384](http://127.0.0.1:8384) to access the syncthing webUI

#### On Windows
I haven't used syncthing on Windows, but you can check [this video](https://www.youtube.com/watch?v=02XeIATCDO4).

#### On Android
The service should be automatically started once you access the app and check the start conditions

#### In the webUI
[Video form](https://www.youtube.com/watch?v=02XeIATCDO4)

Now that your services are setup, you want to link them. Head to [http://127.0.0.1:8384](http://127.0.0.1:8384).
On your laptop or computer, add a new folder to share under "Folders" > "+ Add Folder".
You can label the folder anything you want, I named it "All Songs."
The folder ID can also be modified, just make sure you don't use special characters or spaces. Something like "all-songs".
On the folder path, add in where you downloaded your music from yt-dlp, for me it was `/home/hyperboly/Music/allSongs`.
You can check by going to where you downloaded the music and copying the output of `pwd`.

After you add the folder, click on "Actions" in the top right corner of the webUI.
Click on "Show ID", and go to your syncthing app on your phone.
On your phone, select devices and on the top right corner press the add new device icon.
Press on the QR icon on the right of ID, and scan the QR code on your laptop.
Create a name for the device and press the checkmark.
This should add the device.

Now on your laptop, there should be a dialogue box that tells you your phone wants to link up, confirm it.
Click on the music folder you added and press "Edit".
Select "Sharing" in blue text and tick the checkbox for your phone's name that you set.
Now your phone should have a notification to confirm sharing the folder, confirm it and set where you want the download to go.
The syncing should start now and you are basically finished.

## What Now?
Android has a terrible default music player, I suggest you use Vinyl from fdroid if you want a better experience.

You can use syncthing for things other than music, on as many devices as you want.

Adding music to your playlist on youtube won't automatically add it to your downloads.
When you want to update your downloaded playlist, just run the same command (or my script) again and it will automatically download the new music from Youtube.
When your playlist folder on your computer updates, syncthing will sync your phone up at the same time.

Drawbacks: Syncthing will only sync when you are connected to the same network (same wifi, same router...) so if your phone isn't connected to the same wifi as your computer, your files will not sync.
