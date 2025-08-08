---

title: "Migrating ISC DHCP to Dnsmasq in OPNsense"
date: 2025-08-08T17:54:33+08:00
author: John Wu
description:
tags: ['tech', 'guides']
toc: true
draft: false

---

# What You'll Need
- CSV spreadsheet of your reserved IPs (if you have any)
This is what the headers look like, add more hosts via rows:
![CSV of IPs](/images/guides/ip-csv.png)

# Importing the CSV
In OPNsense, open the webpage under Services > Dnsmasq DNS & DHCP > Hosts.
There should be an import button in the UI, just upload the CSV file and you should be good.

# Setting DHCP Ranges
Under Services > Dnsmasq DNS & DHCP > DHCP Ranges, click add and fill in the values.
Reference your old configuration with ISC and you should be fine.

> NOTE: Theres no need to set Tags. Don't set constructors if using IPv4

> TIP: Once you have 1 range set, you can just clone them and create new ones pretty quick. Same with setting DNS later.

# Setting DNS
I don't use the native OPNsense DNS server (unbound), instead I use pihole on my main server so I'm not sure how this part goes with a local unbound service.

Under Services > Dnsmasq DNS & DHCP > DHCP Options, add a new option (not Boot).

| Option name   | value    |
|--------------- | --------------- |
| Type  | Set  |
| Option   | dns-server [6]   |
| Option6  | None   |
| Interface   | Whatever interface you are setting   |
| Tag   | None |
| Value | DNS Server IPs |
| Force | unchecked |
| Description | This is my description |

Clone this as many times as needed, setting a new interface each time.

# Enabling and Testing Dnsmasq
Head to System > Diagnostics > Services and turn off "DHCPv4 Server" and turn on "Dnsmasq DNS/DHCP."

To test this, on Windows you'll enter the command `ipconfig /renew`.
On Linux the command will depend on which DHCP client you are using.
By default in Debian it is dhclient:
```
# dhclient -r interface_name && dhclient interface_name
```

If your IP does not change (for reserved IPs) or the DNS server is set correctly, then you have successfully migrated


RIP ISC
