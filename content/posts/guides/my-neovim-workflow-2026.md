---

title: "My Neovim Workflow 2026"
date: 2026-01-16T16:00:59+08:00
author: John Wu
description: New configuration of vim I'm using on Nix now.
tags: ['tech', 'guides', 'vim']
toc: true
draft: false

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

To test your flake, run `nix build .` in the project directory.

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

That's pretty much all you have to do for the LSP, luasnip is already configured and if you want to tweak the servers, the documentation is all in the comments of the `init.lua` file.

# Harpoon
If you want to use harpoon in the configuration, you'll need to first add it to the `flake.nix` file.
```nix
startupPlugins = with pkgs.vimPlugins; {
  general = [
    harpoon2
    ...
  ];
}
```

Then in `lua/custom/plugins/harpoon.lua`
```lua
return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
  },
  config = function ()
    local harpoon = require("harpoon")

    -- REQUIRED
    harpoon:setup()
    -- REQUIRED

    vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
    vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

    -- Toggle previous & next buffers stored within Harpoon list
    vim.keymap.set("n", "<C-p>", function() harpoon:list():prev() end)
    vim.keymap.set("n", "<C-n>", function() harpoon:list():next() end)
  end,
}
```

# Add to System Flake
Since you've already created a public repo on the internet, for me I created one on github, we can easily use the flake as an input.
```nix
inputs = {
  ...
  nixcats-nvim = {
    url = "github:hyperboly/nixCats-nvim"; # Change with your own
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };
};
```

Then either in your environment package or your home package list, add `inputs.nixcats-nvim.packages.${pkgs.system}.nvim`.
Example:
```nix
home.packages = with pkgs; [
  inputs.nixcats-nvim.packages.${pkgs.system}.nvim
];
```

You'll want to remove the other instances of neovim in your configuration either from `programs.neovim` or equivalent.

Now if you rebuild your system flake and run `nvim` it should be the flake that you created with nixCats!
