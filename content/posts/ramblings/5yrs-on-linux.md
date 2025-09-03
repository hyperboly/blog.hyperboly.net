---

title: "5 Years on Linux"
date: 2025-08-31T17:50:18+08:00
author: John Wu
description:
tags: ['ramblings', 'tech']
toc: true
draft: true

---

Since it's nearing 6 years I've been using linux, I just wanted to write about my experiences with Linux.
Or as I've recently started referring to it: GNU/Linux.

# Beginnings
Linux first appealed to me because of privacy and internet freedom.
I think there was also a rebellious mentality that led to me not wanting to use Windows as well.
Back in 2019, I was my senior year of middle school when the idea of digital privacy and freedom floated around my YouTube feed for a while.
[Mental outlaw](https://www.youtube.com/@MentalOutlaw) and [Luke Smith](https://www.youtube.com/@LukeSmithxyz) were a lot what I was consuming, and when I got my first laptop, I made sure to get an AMD one since the internet told me that AMD would be more compatible with desktop Linux.
This is less of an issue now in 2025, since AI has forced NVIDIA to actually create some open source drivers.
Back before 2019, I was pretty much computer illerate, I guess I knew how to open up Minecraft and knew about files and folders.
Some people in middle school have already figured out game modding but since I wasn't a PC gamer I did not have any experience of anything truly technical.

## First Laptop
My first laptop is basically a trash consumer laptop that HP put out for budget consumers, at the time it was 24k NTD?
That's around 785USD, which is quite a lot for the build quality and components it has.
The model was a [14s-fq1002AU](https://support.hp.com/hk-zh/document/c07860163), which wasn't sold in the US so the link is in Chinese.
CPU wise it's actually a pretty good chip, the problem is everything else.
Keyboard is not great, touchpad is awful (the top film starting wearing off after a year), and the outer shell is really flimsy plastic.
The main problem with it was the Wifi chip, the RTL 8852ae.

## First Taste of the CLI
After unboxing, Windows 10 was preinstalled and Wifi worked completely fine.
I think HP must've told retailers to plug it into ethernet and install drivers first because when I tried installing Linux Mint, the Wifi was just completely non existent on the GUI menus.
I can't remember the entire process but my more technically proficient dad told me maybe the drivers just don't exist for Linux.
My first problem was knowing that drivers are even a thing, much less knowing how to install a driver on Linux manually.

At some point, maybe my third day researching it, I came across [lwfinger's rtw89 repo](https://github.com/lwfinger/rtw89).
This repo contained the drivers I needed to get the card working, although I don't think I fully understood what I was doing.
For a couple of days, I learned how to follow the directions in the README, which thinking back now is a really simple process.
I think the biggest hurdle was getting through the pain of wrapping my head around different concepts since not knowing very basic concepts ruins my ability to follow directions.

Installing Wifi was also a pain because of the trash quality of the IO.
The USB A dongle for ethernet I needed kept disconnecting because of instability with the hardware.
It took me several tries before I actually could even install `git`, and then `git clone` the repo.

As a side note, in 2022 I finally decided to try Arch on my laptop and made [this issue](https://github.com/lwfinger/rtw89/issues/124) because I forgot how to install the drivers.

## PopOS
Throughout the process of installing the Wifi drivers, I came across PopOS and really liked the UI.
At the time, I wasn't attached to the Windows UI out of familiarity because I really wasn't familiar with Windows either.
Nowadays I avoid gnome when possible because I don't want to learn how to use it properly.

I stayed on PopOS for a couple of years, it was the first distro that I learned what I needed to leave it.
I remember in senior year middle school Social Studies class going through VimTutor to learn the editor since I saw Mental outlaw and Luke Smith use it.
Vim surprisingly was kind of intuitive to me, took me a couple of days to get used to the hjkl paradigm.
It won't be until several years later that I learn how to configure it though.
The default binds and features were enough for the configuration work I will be doing for a couple of years.

## Minecraft Server
Entering highschool, my friends wanted a Minecraft server.
We started off by using the free to use Aternos hosting service, but the lag was almost unbearable.
Also, one of the admins had to be online to turn the server on because there's a timeout on Aternos where if no users are in the server, the server shuts down after the timeout.

My solution was to self host.

# Arch

## Ricing/DWM

### Qtile

### Hyprland

## Homelab

# Automation

## Nix

## Ansible
