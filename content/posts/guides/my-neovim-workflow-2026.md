---

title: "My Neovim Workflow 2026"
date: 2026-01-16T16:00:59+08:00
author: John Wu
description: New configuration of vim I'm using on Nix now.
tags: ['tech', 'guides', 'vim']
toc: true
draft: true

---

My last neovim article was from 2024 and I've finally taken the time to rewrite the atrocity that was the neovim unwrapped version I had in 2024.

# What's Different
- [Link to repo](https://github.com/hyperboly/nixCats-nvim)
- Using NixCats this time because I can understand nix a bit better
- Not many changes other than more plugins from kickstart.nvim.
- I am still using nixOS but this guide should work with non nixOS distros that just have the package manager. You might have to tweak it a tiny bit, follow the nixCats docs.

# NixCats
Using NixCats is quite simple if you have worked with other nix projects before.

1. You want to select a [template](https://nixcats.org/nixCats_templates.html), personally I choose the kickstart.nvim one because I've already worked with kickstart before.
2. You then want to create a directory to work in that is NOT already in your system flakes directory (eg. `mkdir ~/nixcats-nvim`).
3. Flake init. For the kickstart.nvim template `nix flake init -t github:BirdeeHub/nixCats-nvim#kickstart-nvim`.
4. Git init, git add, git commit, git set upstream (you'll need to create a repo on github or equivalent beforehand).

At this point, you should be 90% done, all you need to do is tweak the settings in init.lua to whatever you like then add it to your system.

# LSP
To add more languages to the LSP, you'll have to first add the packages from nix to the `flake.nix` file.
```nix
# flake.nix

# lspsAndRuntimeDeps:
# this section is for dependencies that should be available
# at RUN TIME for plugins. Will be available to PATH within neovim terminal
# this includes LSPs
lspsAndRuntimeDeps = with pkgs; {
  general = [
    universal-ctags
    ripgrep
    fd
    stdenv.cc.cc
    nix-doc
    lua-language-server
    tree-sitter
    nixd
    stylua

    # added
    yaml-language-server
    clang-tools
    pyright
    docker-compose-language-service
    bash-language-server
    gopls
  ];
```

Then to your `init.lua` file, you'll need to find the string "local servers = {}", and then make it look something like this.
```lua
local servers = {}
servers.clangd = {}
servers.gopls = {}
servers.pyright = {}
servers.docker_compose_language_service = {}
servers.yamlls = {}
```

# Harpoon

# Add to System Flake
