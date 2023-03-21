---

title: "LACP on OPNsense"
date: 2023-03-19T19:26:15+08:00
author: John Wu
tags: ['tech','guides']
ShowToc: true
summary: "How to configure OPNsense with LACP"
draft: true

---

## My Setup
- Hardware:
    - 4 port NIC for LAGG on OPNsense, 1 port for WAN
    - Zyxel GS1900-8

## Prerequisites
- Backup your current configuration
- Needs to be a clean system
    - No VLANs
    - Preferably fresh install
