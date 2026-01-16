---

title: "Nixcats"
date: 2026-01-16T16:00:54+08:00
author: John Wu
description:
tags: ['tech', 'vim']
toc: true
draft: false

---

# January 2026
So I've realized the last time I changed my neovim config was 2024.
For the past 2 years, every major nix release (25.05, 25.11), I would get errors screaming at me to fix neovim.
My response would just be patching some nix code or removing some feature that I wouldn't mind losing to inconvenience myself.
This time I upgraded my nix system and neovim was one again broke.
I have gained a lot more experience with nix and programming in general in 2025, so I thought I would tackle the challenge of changing my neovim configuration.
After researching which approach is best, I settled on nixCats.

# NixVim, NVF, NixCats, etc...
The first one I looked at was NixVim and NVF, popular projects back when I first started using nixOS.
They provide a really simple nix module for neovim that can be configured as a module simply in the system flake.
They also supports using raw lua for configuration.

The biggest hurdle for me was that I liked the kickstart.nvim ease of configuration and I wasn't willing to learn both neovim and these new tools at the same time.
Since nixCats provides a template for kickstart.nvim, I chose nixCats.

In the future, if there is a really good reason to switch off and learn a new project, you'll probably see "My Neovim Configuration 202X."

# NixCats
NixCats has a simple philosophy: "Nix is for downloading. Lua is for configuring."
Since I already had a configuration in lua, the migration to nixCats was mostly painless (read [my 2026 setup](/posts/guides/my-neovim-workflow-2026)).
There might be some reproducibility problems with it that I'm not seeing but personally I think it's as reproducible as NVF or NixVim or any of the other options.
I understand some people despise the lua language but I can tolerate the indexing starting at 1 and other weird things lua does.
To me, it's just a matter of habits and getting used to the language.

The main reason I picked nixCats is because it's actively maintained, allows me to import my Lua files pretty easily, and the documentation is understandable enough for me to not have to struggle too much.
