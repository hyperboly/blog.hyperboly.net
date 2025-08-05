---

title: "TEAC AI303 Linux"
date: 2025-05-05T15:16:56+08:00
author: John Wu
description:
tags: ['tech', 'guides']
toc: true
draft: false

---

# Software/Hardware
Here is the audio stack I'm using:
1. Pipewire/wireplumber
2. Pipewire pulse
3. Pipewire Jack

As the title says, I'm using the TEAC AI-303 DAC although the specific model should not matter.
You can try this regardless of model of DAC, if it has USB it will likely work.

# Finding sound card
For checking if a different sample rate will work with a 16bit rate, I used ALSA.

First, find your device ID with `aplay -l`.
```
card 3: AI303 [AI-303], device 0: USB Audio [USB Audio]
  Subdevices: 0/1
  Subdevice #0: subdevice #0
```
Note that it is "card 3"

# Configuring Pipwire
Now you can do `pactl list cards` and get all the info on your DAC.
Copy paste the name for now.
Create a new file `~/wireplumber/wireplumber.conf.d/50-anynameyouwant.conf` and include these lines:
```
monitor.alsa.rules = [
  {
    matches = [
      {
        node.name = "name of your device you copy pasted. ie alsa_output.pci-0000_2d_00.4.analog-surround-51"
      }
    ]
    actions = {
      update-props = {
        audio.format = "whatever rate you want that was listed under stream0. ie S24LE",
        audio.rate = "whatever rate you want that was listed under stream0"
      }
    }
  }
]
```

You'll want to check which rates are available with `cat /proc/asound/card3/stream0`
If the rate you select doesn't work, try something else until it does.
The most common combination that works will be 44.1kHz and 16bit.
If this combination works, try to increase either number until it doesn't.

Here is my config:
```
monitor.alsa.rules = [
  {
    matches = [
      {
        node.name = "alsa_output.usb-TEAC_Corporation_AI-303-00.analog-stereo"
      }
    ]
    actions = {
      update-props = {
        audio.format = "S24LE",
        audio.rate = "96000"
      }
    }
  }
]
```

# Nix
Since nix does not officially support this config, I had to use `home.file."/home/user/..."`
```nix
# teac-ai303.nix
{config, ...}:

{
  home.file."${config.xdg.configHome}/wireplumber/wireplumber.conf.d/50-ai303.conf".text = ''
    monitor.alsa.rules = [
      {
        matches = [
          {
            node.name = "alsa_output.usb-TEAC_Corporation_AI-303-00.analog-stereo"
          }
        ]
        actions = {
          update-props = {
            audio.format = "S24LE",
            audio.rate = "96000"
          }
        }
      }
    ]
  '';
}
```

# Motivation
I've had this TEAC AI 303 DAC for a couple of years doing nothing because I can only play CDs on it.
A couple of weeks ago I found out how to get this DAC working without using a Windows VM to play audio on it.

I never knew this but DACs don't output sound if they can't read it, sort of self explanatory but I had no idea.
I'm used to playing audio and the hardware just working, not having to tweak the bitrates and sample rates.

# DACs Suck
Most DACs will only take a couple of bitrates and sample rates to actually output sound.
Of course, they don't tell you what bitrates and what frequencies.
What you'll have to do to actually get the DAC to output sound at a bitrate you can accept is just trial and error.

Some DACs (maybe most?) also limit bitrates work based on if you have their software or not.
I was not able to get the highest bitrate and sample rate that USB was rated to be able to go.
