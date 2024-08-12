---

title: "My Own Enterprise Environment"
date: 2023-09-09T19:16:24+08:00
author: John Wu
description: "A look at the progress in my homeserver and some historical notes."
tags: ['tech']
toc: true
draft: false

---

I'm ready to put on a suit and tie, sit in a cubicle, and fantasize about being productive.

# The History of This Setup
My homeserver according to how long my current install of Proxmox was started on June 9th, 2022.
I used Linux as a desktop for a couple of months before that and ran a shoddy Ubuntu server for a month before.
So, it's now September of 2023 and my homeserver has evolved since then, which is why I'm documenting it's progress.

# Current Homeserver
## Physical Servers
I have 2 towers for this homeserver, one is pretty decked out the other not so much.
I won't touch on the specific hardware because I'll have to dig for a list I lost a long time ago.
The only hardware I'm sure of is the GPU in Proxmox, which I go much in depth of what I do with it in [this article](/posts/guides/gpupassthroughamd6600).

### Proxmox (PVE)
The physical server for this homeserver hasn't changed in a year, although I'm planning to get 2 NVME's soon for a RAID1 reinstall of proxmox.
The one thing that did change in PVE is the GPU, which I removed and am waiting on a replacement GPU.
I removed the GPU because I didn't really need a desktop workstation and didn't play many games, and the stuff I do I just need my laptop.
I still need a replacement GPU because my CPU doesn't have integrated graphics so if anything goes wrong I'm stuck without a BIOs or CLI.
Currently I'm looking at the GT730.
For the boot drive, it has a 512G NVME drive that came with the MOBO, which is cool.
However, I'm again, looking to buy another NVME and reinstall proxmox with ZFS.

Throwing in the NAS, I have it virtualized under PVE but passed through the individual drives.
I sort of regret it but sort of not.
The main thing I regret is not labelling the drives' UUID for when they inevitably die on me.

### OPNsense
For OPNsense, I'm running some generation of an i3 and the boot disk is some spare SSD picked out from the dump.
This computer was mainly just picked up from a dump, I live near a university and their 3C hardware just gets renewed every couple of years I guess.
It runs well on 8G of RAM and hasn't died on me yet, though I doubt it's stability especially with the shoddy SSD.

OPNsense only came in after I realized I needed VLANs in my network when I started getting into CTFs.
Just the awareness of things bots do on the internet and some of the stories scared me into improving security in my homeserver.
If only by a little.

### Networking Devices
I have only 3 networking devices that really matter outside of OPNsense: my Zyxel switch, netgear switch, and netgear AP.
All of them are gigabit connection, which is fine, despite what some people would say.
For most workloads, I can wait for a file transfer a little longer than if I had 2.5, though it would be nice :)

The Zyxel switch (GS1900) is the only one that can handle LACP (LAGG), so I put that between my OPNsense and the rest of the network.
It's got 4 ports all linked up so if I had 4 different connections, it would have gigabit speeds all around (rarely happens from my monitoring, so again, why need 2.5Gb?).
This one I got for free after a few months into my homeserver because a teacher who also has a homeserver gave it to me (he switched to all UniFi).

My dumb but managed netgear switch (GS305E) is the only switch I haven't configured VLANs on because I really don't know how to and it connects to some family, which makes it sort of production and I need to find downtime to get play around with it.
I got this switch early in my homeserver because the AP at the time didn't have enough ports to connect to my server.

The netgear AP (WAX610) is pretty cool because it has WiFi 6, even though all my devices can't connect to it my family's Apple devices can, which is cool.
It's also the newest hardware for my homeserver, when I got it around June because the original D-Link trash couldn't have more than 1 SSID.

## Virtual Insanity
Of course, being a proxmox user, I enjoy virtualization and the ease that PVE gives me to do it.
Unfortunately, this is not a enterprise hypervisor solution from what I've seen online; especially in Taiwan because most companies are using Hyper-V as their type 1 hypervisor solution.
I've been wanting to get into Windows but Linux is what I'm comfortable with and it's hard to motivate myself to touch something I deem as unethical.

Although I'm an Arch user on the desktop, all my LXCs and VMs are Debian12.
Currently, I'm running 6 VMs and 8 LXCs.
I run VMs for things like Docker, high security risk services, and TrueNAS.
For example, some services like this blog are exposed to the internet (pls no hack), so I put Cloudflare (pls no laugh) in front of it and HAproxy under a VM.
Although I doubt I'll get DDoSed, it was fun to learn about high availibility servers and the CI/CD things I needed to deploy from my laptop to the servers.
The DMZ network that this blog runs on are also completely separated from my other servers or WiFi, anything else for added security too.
My information is pretty useless anyways, if you want to encrypt it, don't expect me to pay some petty ransom.
My information is useless unless you're some government or company... if you are then go away, stop listening to me on my phone.

I don't trust docker too much because of the historical vulnerabilities proving it was not built to be secure + the security primarily depends on the devs.
Despite all the conveniences Docker brings, if the devs don't update the packages regularly in the container, even if you run all the best practices on Docker you can still have a high chance of being compromised.
I run it in a VM because it means it needs to break out of the Docker and then out of the VM, which is unlikely in my threat model.

# Security

## Threat Model
The main threat I perceive in my network are bots from Shodan or some script kiddies looking for an easy metasploit target.
Stories I've heard from Darknet Diaries such as WannaCry has me scared straight.
When a rogue government sponsored virus goes loose, there's nothing I can really do about it because most likely they're using a 0day exploit.
Or, if someone releases a few 0days for free and malware gets written for those then I really can't do anything until Debian releases an update.
The main people I have to watch out for are existing bots and freely available malware floating around.
Things I can semi-confidently deal with.

I have 2 holes in my firewall, which means if some bot finds these openings, they'll start hammering away.
Currently my prevention has been Crowdsec on OPNsense, which in theory should be banning all these bad actors, but I don't trust it enough because it's such a new project.
The biggest thing that can go wrong is someone breaks into my homeserver and escalates priviledges to root on my proxmox, which basically means all my servers are gone.
Although the chances are low, God has a way with life.
I also have not set up monitoring syslogs YET (a project for tomorrow), which is another massive hole in my security.
Graylog, ELK, or other logging solutions are just new technologies to me and I have no clue where to start.

My main mitigation right now is segregation.
My DMZ with the servers exposed to the internet can't talk to anything in my house.
All of the services are containerized either in LXC or a VM.
Although LXC's have worse security than VM's, they are unpriviledged containers.
The last mitigation is my SSH jumphost.
My jumphost is secured as well as possible to my knowledge and it's sort of a convenience feature as well because I set up a tmux session that has all the SSH configurations, which I never got around to creating in my workstation.
One thing I have been planning to do after I set up more security measures (logging mostly) is to try and pentest my own homeserver.
First from the outside and then from the inside, see what I can exploit as an idiot script kiddie myself.

There are obviously many steps I still have to make to have this homeserver tighter in security, but for now I have most of the elements of a small size enterprise.

# Is It Enterprise Enough?
Over the past year of doing homeserver stuff and learning enterprise procedures through certification books, no, it's not enterprise enough.
This is not enterprise enough.
I'm sure anyone skilled in offensive cybersecurity could break into my servers easily, as I'm also sure any defensive security professional would look at my setup and point out a million flaws.
I do not have an LDAP server or CA to verify every user on my network.
Neither do I need one, unless I'm managing 200-1000 users that I have to think of as a security risk.
I only have 3 family members that are walking phish, and just putting them on a separate VLAN is enough for me.

What I do have is both a practical and useful environment that practices enterprise security hygiene.
The purpose of my homeserver was not really to learn about servers (though it is a primary goal), but to be able to use it extensively to get value outside of education.
In my mind, that's a win.
