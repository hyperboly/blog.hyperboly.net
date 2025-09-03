---

title: "Simple Mc Server"
date: 2025-09-01T20:38:56+08:00
author: John Wu
description:
tags: ['guides', 'tech']
toc: true
draft: false

---

# Goal
The goal of this guide is to get you a Debian system installed with a Paper Minecraft server that is started on boot by Systemd.
It will also include an optional choice of adding a firewall to the server.
To play from outside of LAN, this guide will NOT explain how to port forward or set up a VPN.

This guide explains setting up an almost vanilla build of minecraft at the latest versions (1.21.x).

# Setting Up
To start with you'll need a Debian or Ubuntu system.
This article will focus on a Debian system.
To install Debian, follow [ this ](https://www.debian.org/releases/stable/amd64/ch03s01.en.html) or [this](https://debian-handbook.info/browse/stable/sect.installation-steps.html).

You'll want to first update and upgrade your system before these steps, while we do that we can also install a couple of packages we'll need:
```sh
sudo apt update && sudo apt upgrade -y && sudo apt install vim unattended-upgrades screen unzip
```

# Minecraft Server
For Minecraft 1.21.x and above, we'll need to install openJDK 21.
The easiest way I've found of doing this is from the microsoft repositories, install openJDK following [ these instructions ](https://learn.microsoft.com/en-us/java/openjdk/install#install-on-debian)

Verify Java 21 is installed:
```sh
java -version
```

## Creating Server Files
First we have to do is create the server files.
Let's create a directory for our minecraft files.
```sh
mkdir ~/mc-server
cd ~/mc-server # change directory
```
Go to the Fabric website and download (via `curl`) [the server Jar file](https://fabricmc.net/use/server/).

Now you can generate the server files by running the jar file, example command:
```sh
java -Xmx2G -jar fabric-server-mc.version-number.jar nogui
```

Once ran, the process should stop by itself on first run and say "[main/INFO]: You need to agree to the EULA in order to run the server. Go to eula.txt for more info."
Run this:
```sh
echo "eula=true" > eula.txt
```

Now if we execute the jar it should work fine, you can stop the server by typing `stop` if you are stuck in Minecraft's console.
At this point you are pretty much done but the server must be started manually everytime the host reboots.
To fix this, you'll need to create a systemd service.

## Creating a Systemd Service
Creating a systemd service is quite simple, write the service file and enable the service.
```sh
mkdir -p ~/.config/systemd/user
nano ~/.config/systemd/user/mc-server.service # Paste the next section and "ctrl+xy" to exit nano
systemctl enable --now --user mc-server.service
```

Here's `~/.config/systemd/user/mc-server.service`, you'll have to change the "WorkingDirectory."
```
[Unit]
Description=Minecraft Server
After=network.target

[Service]
WorkingDirectory=/home/user/mc-server/
Restart=always
StandardOutput=journal

ExecStart=/usr/bin/screen -DmSL mc-server/usr/bin/java -Xmx2G -jar fabric-server-mc.1.21.4-loader.0.16.14-launcher.1.0.3.jar nogui

ExecStop=/usr/bin/screen -p 0 -S mc-server -X eval 'stuff "say SERVER SHUTTING DOWN IN 15 SECONDS..."\015'
ExecStop=/bin/sleep 5
ExecStop=/usr/bin/screen -p 0 -S mc-server -X eval 'stuff "say SERVER SHUTTING DOWN IN 10 SECONDS..."\015'
ExecStop=/bin/sleep 5
ExecStop=/usr/bin/screen -p 0 -S mc-server -X eval 'stuff "say SERVER SHUTTING DOWN IN 5 SECONDS..."\015'
ExecStop=/bin/sleep 5
ExecStop=/usr/bin/screen -p 0 -S mc-server -X eval 'stuff "save-all"\015'
ExecStop=/usr/bin/screen -p 0 -S mc-server -X eval 'stuff "stop"\015'

[Install]
WantedBy=default.target
```

## Optional: Mods
To install mods for the server is quite simple:
download the mods into the `mc-server/` directory and move it to the mods directory.

I use Modrinth.
If I wanted to install the modpack [Simply Optimized](https://modrinth.com/modpack/sop), I'll have to unpack it.
You'll have to use something like [this](https://fabulously-optimized.github.io/mrpack-to-zip/) to get it packed into a zip.
Once you have it downloaded, you want it in the root of your minecraft server directory.
Meaning, if you do an `ls` you should see the minecraft server `.jar` file.

```sh
unzip Simply-optimized.zip
```

And the mods files/config stuff should be extracted to the correct locations.
