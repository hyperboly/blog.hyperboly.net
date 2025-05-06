---

title: "TEAC AI303 Linux"
date: 2025-05-05T15:16:56+08:00
author: John Wu
description:
tags: ['tech']
toc: true
draft: true

---

So I've had this TEAC AI 303 DAC for a couple of years doing nothing because I can only play CDs on it.
A couple of weeks ago I found out how to get this DAC working without using a Windows VM to play audio on it.

I never knew this but DACs don't output sound if they can't read it, sort of self explanatory but I had no idea.
I'm used to playing audio and the hardware just working, not having to tweak the bitrates and sample rates.

# DACs Suck
Most DACs will only take a couple of bitrates and sample rates to actually output sound.
Of course, they don't tell you what bitrates and what frequencies.
What you'll have to do to actually get the DAC to output sound at a bitrate you can accept is just trial and error.

# Checking if different frequencies work
For checking if a different sample rate will work with a 16bit rate, I used ALSA.

First, find your device ID with `aplay -l`.
