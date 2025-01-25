---

title: "Primitive Ansible"
date: 2025-01-25T12:50:30+08:00
author: John Wu
description:
tags: ['Tech']
toc: true
draft: true

---

I've been using ansible for maybe half a year now and I think the workflow I've got with it is pretty mature for the scale usecase that I have.
For those that don't know, [ansible](https://ansible.com) is a RedHat tool that automates things that traditionally I would use a shell script for.
Some usecases include installing packages, updating, or changing locales on new systems.

This is not a guide, just a few notes for ansible that I find useful.

# File Structure
For some reason, [ansible documentation](https://docs.ansible.com/ansible/2.8/user_guide/playbooks_best_practices.html#directory-layout) for the filestructure is quite lacking and I had to read it a million times to do some basic stuff.
One thing that took a while to realize were that file names *matter*.
Here is the file structure in my configuration currently:
```
├── ansible.cfg
├── compose
│   ├── gotify
│   │   └── docker-compose.yml
│   ├── grafana
│   │   └── docker-compose.yml
│   ├── ...
│   │   └── docker-compose.yml
├── files
│   ├── locale
│   ├── prod-zabbix-agent2.conf
│   └── staging-zabbix-agent2.conf
├── install_docker.yml
├── inventories
│   ├── production
│   │   ├── group_vars
│   │   │   ├── all.yml
│   │   │   ├── lxc
│   │   │   │   └── update.yml
│   │   │   └── vm
│   │   │       └── update.yml
│   │   ├── host_vars
│   │   │   ├── blog
│   │   │   │   ├── blog_plain.yml
│   │   │   │   └── blog.yml
│   │   │   ├── caldav
│   │   │   │   ├── caldav_plain.yml
│   │   │   │   └── caldav.yml
│   │   │   ├── ...
│   │   └── inventory.yml
│   └── staging
│       ├── group_vars
│       │   └── all.yml
│       ├── host_vars
│       │   ├── staging-caldav
│       │   │   ├── caldav_plain.yml
│       │   │   └── caldav.yml
│       │   ├── staging-gotify
│       │   │   ├── gotify_plain.yml
│       │   │   └── gotify.yml
│       │   ├── ...
│       └── inventory.yml
├── ping.yml
├── provision.yml
├── update_docker.yml
├── update.yml
└── zabbix-agent2.yml
```

The playbooks mainly target Debian LXCs and Debian VMs on my Proxmox server (yes I've gone all in on Debian).
The first I'll note is the inventories directory.
Under `inventories/` there is `production` and `staging`.
Under each category, there is an `inventory.yml` file, `group_vars`, and `host_vars` directory.
The `inventory.yml` defines all the hosts, the `group_vars` directory defines variables for all hosts in the file name (for example `all.yml` will define variables for all hosts in the inventory, or creating an `lxc/` directory will define variables for all lxc hosts in the inventory).
Under `host_vars`, I store all the passwords for the hosts with ansible-vault.

In the root directory, I have all the playbooks just scattered around because I'm too lazy to define another directory when I'm calling the playbooks.

The `compose` and `files` directory is where I store things that I can copy over to the server.
This is mainly because I use docker compose instead of pure docker or kubernetes.
For example, if I had a graylog app that I wanted to spin up, I just define a `graylog` host, set the same password and user, then run the `install_docker.yml` file and it will install the docker binary plus the compose file and start running the app.

# Ansible Vault
I use ansible-vault to store all my passwords, there's no real reason.
Everything on my server is completely local on my laptop (and backed up to my server), this is more for learning about ansible.
In my inventory, I have a `host_vars` directory and under it are a bunch of directories with their respective *hostnames*.
The hostnames part is important because that's how ansible know's which variable is for what.
Under each hostname directory, for example `app/`, there are 2 files: 1 encrypted 1 plaintext.
In the plain text file I would write `ansible_become_pass: "{{ vault_app_pass }}"`.
In the encrypted file I would write `vault_app_pass: "verycoolpassword"`.

This makes it so that I have to unlock the encrypted file during execution so that the `app_plain.yml` file can read the encrypted variable otherwise it will error out.
It's important to note that every encrypted file needs to have the same password.
When you run `ansible-playbook install_docker.yml` or something similar you need to append the `-J` flag so that it will prompt for the vault password.

# Server Prerequisites
With the way that I use ansible, there are several prerequisites required before running the playbook.
1. The password for sudo must be set and synced with the playbook (I didn't find a way to automate this).
2. There must be a root AND normal user (UID 1000 GID 1000) with passwords.
3. There needs to be an sshd server running on the client.
4. This is not OS agnostic so the OS must be debian (maybe Ubuntu), otherwise you'll need to patch it other distro specific stuff like the package manager.

Some of these steps I automate with cloudinit or I have an LXC template that has 90% of this set up.
The most tedious part is setting a password on the server and adding that to the inventory.


That's about it for all the less documented stuff that I want to take a note of.
Writing the playbooks is the easiest part because it's also the most documented, most of what I wanted to do have already been done.
