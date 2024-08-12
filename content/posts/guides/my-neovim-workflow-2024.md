---

title: "My Neovim Workflow 2024"
date: 2024-08-12T05:22:47+08:00
author: John Wu
description: A new and updated version of how I use neovim on a daily basis
tags: ['tech', 'guides']
draft: false
toc: true

---

Last year I wrote [my neovim workflow 2023](/posts/guides/my-neovim-workflow-2023/) and a little bit has changed since then, so I'll write an updated version. Here's where my config starts: https://github.com/hyperboly/nix-dotfiles/blob/master/user/neovim/neovim.nix

This article is written for people that have used neovim before, but did not go deep into the configuration part (me).
Some concepts in neovim are assumed, nix concepts are explained.

# What's different
- OS
- Switched to [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) as the base and not using my own

# NixOS
Last year, I was using Arch Linux and had an easier time integrating neovim into my system.
This time, since I'm on NixOS, I had to configure nix **for** neovim.
Packages for neovim plugins come from [nixpkgs](https://search.nixos.org/packages?channel=24.05&from=0&size=50&buckets=%7B%22package_attr_set%22%3A%5B%22vimPlugins%22%5D%2C%22package_license_set%22%3A%5B%5D%2C%22package_maintainers_set%22%3A%5B%5D%2C%22package_platforms%22%3A%5B%5D%7D&sort=relevance&type=packages&query=neovim+plugins) and neovim has to use those "system" packages instead of it's own package manager like [packer.nvim](https://github.com/wbthomason/packer.nvim) or [lazy.nvim](https://github.com/folke/lazy.nvim).

Aside from that, most of the configuration in Lua can remain the same.

## File structure
The directory structure looks like this:
```
user/neovim/
├── conf
│   ├── init.lua
│   └── lua
│       ├── custom
│       │   └── plugins
│       │       └── init.lua
│       ├── keymaps.lua
│       ├── kickstart
│       │   ├── health.lua
│       │   └── plugins
│       │       ├── autopairs.lua
│       │       ├── cmp.lua
│       │       ├── colorscheme.lua
│       │       └── ...
│       ├── lazy-bootstrap.lua
│       ├── lazy-plugins.lua
│       └── options.lua
└── neovim.nix
```
I didn't delete some files from kickstart that aren't needed in nix, but they don't take up too much space.

## `neovim.nix`
*This configuration is used by home-manager, do not use this with the system package because neovim plugins do not need to be root level.*

Let me show you how my `neovim.nix` file is organized section by section.

I first set some variables before I get to the actual nix code.
Here, I'm defining `toLua` and `toLuaFile`, so that later when I want to use Lua code in this nix file, I just have to use these variables to convert the Lua.
```nix
let
    toLua = str: "lua << EOF\n${str}\nEOF\n";
    toLuaFile = file: "lua << EOF\n${builtins.readFile file}\nEOF\n";
in
```

Here I define the packages that I want in neovim. Not plugins for neovim, just packages.
```nix
extraPackages = with pkgs-unstable; [
    gnumake
    unzip
    nodePackages_latest.nodejs
    cargo

    lua-language-server
    nil
    yaml-language-server
    ccls
    docker-compose-language-service
    ansible-language-server
    bash-language-server
];
```

The next section I define the packages I want for my plugins, also defining the config/config file that goes with the plugin (similar to the `plugins` directory I had last year).
This is where those variables come in handy.
```nix
plugins = with pkgs-unstable.vimPlugins; [
    {
        plugin = nvim-lspconfig;
        config = toLuaFile ./conf/lua/kickstart/plugins/lspconfig.lua;
    }
    {
        plugin = comment-nvim;
        config = toLua "require(\"Comment\").setup()";
    }
    {
        plugin = catppuccin-nvim;
        config = toLuaFile ./conf/lua/kickstart/plugins/colorscheme.lua;
    }
    {
        plugin = telescope-nvim;
        config = toLuaFile ./conf/lua/kickstart/plugins/telescope.lua;
    }
    {
        plugin = which-key-nvim;
        config = toLuaFile ./conf/lua/kickstart/plugins/which-key.lua;
    }
    {
        plugin = gitsigns-nvim;
        config = toLuaFile ./conf/lua/kickstart/plugins/gitsigns.lua;
    }
    {
        plugin = nvim-cmp;
        config = toLuaFile ./conf/lua/kickstart/plugins/cmp.lua;
    }
    {
        plugin = mini-nvim;
        config = toLuaFile ./conf/lua/kickstart/plugins/mini.lua;
    }
    {
        plugin = todo-comments-nvim;
        config = toLuaFile ./conf/lua/kickstart/plugins/todo-comments.lua;
    }
    {
        plugin = (nvim-treesitter.withPlugins (p: [ # below are just packages that treesitter requires, different package for different languages
            p.tree-sitter-nix
            p.tree-sitter-vim
            p.tree-sitter-vimdoc
            p.tree-sitter-bash
            p.tree-sitter-lua
            p.tree-sitter-luadoc
            p.tree-sitter-python
            p.tree-sitter-c
            p.tree-sitter-markdown
        ]));
        config = toLuaFile ./conf/lua/kickstart/plugins/treesitter.lua;
    }

    telescope-fzf-native-nvim
    cmp_luasnip
    cmp-nvim-lsp
    nvim-cmp
    luasnip
    friendly-snippets
    lualine-nvim
    vim-nix
    fidget-nvim
];
```

This next part defines some extra lua code for the default options, key binds, and the healthcheck that kickstart.nvim includes.
```nix
extraLuaConfig = ''
    ${builtins.readFile ./conf/lua/options.lua}
    ${builtins.readFile ./conf/lua/keymaps.lua}
    ${builtins.readFile ./conf/lua/kickstart/health.lua}
'';
```

The final section just makes it so that when you type `vi` `vim` or use vi for viewing diffs, it will default to this configuration.
```nix
viAlias = true;
vimAlias = true;
vimdiffAlias = true;
```

# Tmux
Tmux configuration remains the same: [read](/posts/guides/my-neovim-workflow-2023/) the tmux section from last year.

This is how I wrote the config in home-manager:
```nix
programs.tmux = {
    enable = true;
    terminal = "xterm-256color";
    prefix = "C-f";
    extraConfig = ''
        set -g default-terminal "screen-256color"
        set -as terminal-features ",xterm-256color:RGB"
        set -g allow-passthrough on

        set -ga update-environment TERM
        set -ga update-environment TERM_PROGRAM
    '';
};
```

# Yazi?
This year, I've also been trying to integrate [yazi](https://yazi-rs.github.io/) into my workflow, but it's not very convenient.

Yazi is a "⚡️ Blazing fast terminal file manager written in Rust, based on async I/O."
It's a file manager like `lf` or `ranger`, but it seems to just get in the way of my workflow.
I use it to organize multiple files because it's able to select files and such, but it doesn't have telescope so I work slower with it.
I would prefer to just use neovim's built in `:Explore`, which I have binded to space+e.

I think I will continue to use Yazi, but not in my normal workflow and only when I need to organize multiple files.


## How it looks like when writing
![Image of my desktop writing this blog](/images/guides/workflow.png)

# Further reading/videos
- [vimjoyer's video](https://www.youtube.com/watch?v=YZAnJ0rwREA)
- [home-manager docs](https://nix-community.github.io/home-manager/)
- [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)
