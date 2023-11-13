---

title: "My Neovim Workflow 2023"
date: 2023-10-29T21:09:16+08:00
author: John Wu
summary: "A guide on how I use neovim for programming, writing, and homework"
tags: ['guides', 'tech']
ShowToc: true
draft: true

---

# [My Config](https://github.com/hyperboly/dotfiles/tree/main/.config/nvim)

This article is a one stop shop for a fully configured neovim setup for C development.
I'm not experienced in Lua, C, or neovim.
Resources at the bottom of the article.

## Neovim?
At its core, neovim (nvim) is a simple text editor.
A text editor is a tool people use to write plain text one, like notepad++ or notepad.
MS Word is a text *processor*, it adds style to the text.

Introduction to neovim:
- Neovim is a fork of Vim, which is an improvement of VI.
- VI is an old text editor that is lightweight and hard to learn, but easy to use.
- Vim (VI iMproved) was created to extend VI by Bram Moolenaar (RIP), therefore calling itself VI improved.
- Neovim is a fork of Vim because vim could only be edited by Bram.

What do I use it for?
- Programming: I use nvim for programming because it's fast, has great tooling, and best of all free software.
- Writing: Right now, I'm using nvim to write this blog.
- Ergonomics: VI probably has the best movement keys, everyone should learn and use Vim movement at some point.

Why make my own configuration?
- I know everything about my configuration.
- I learn more about my text editor that can help me debug issues faster.
- I use Arch btw.

This article will explain my configuration of neovim, not how to use it.

## Starting the Configuration
To start off, there are two packages I'm using available in most Linux repositories:
1. neovim
2. tmux

Once those are installed, the default configuration for our user should be in the `~/.config/nvim/` directory.
Create the directory and write our first file with the name `init.lua`.
> `mkdir ~/.config/nvim ; touch ~/.config/nvim/init.lua`

Next, we want to create a lua folder with our profile.
> `mkdir -p ~/.config/nvim/lua/user/plugins`

By now, our directory structure should look like this
```text
~/.config/nvim
├── init.lua
└── lua
    └── user
        └── plugins
```

This is the directory structure that we want to start off with.
1. The `init.lua` file will just be the file that we link the whole configuration together with.
2. The lua directory is to include all the profiles.
3. The user directory is to specify ourprofile, which should become more apparent later.
This means we can have multiple profiles.
4. The plugins directory is where we'll put all the plugin configuration later.

## Configuring the Profile
In the `lua/user/` directory, we are going to create an `init.lua` file, this will link the files within `lua/user/*`.
We'll write the following lines in this file:
```lua
require(user)
require(set)
require(snips)
require(remap)
```
We'll next create 4 more files like so:
> `touch lazy.lua set.lua snips.lua remap.lua`

Last change for linking our configuration in `~/.config/nvim/init.lua`, write `require(hyperboly)`.
These files mean:
1. `lazy.lua` will be our installation and configuration for the lazy package manager.
2. `set.lua` will be our settings for neovim.
3. `snips.lua` will be where we store our lua snippets (explained later).
4. `remap.lua` will be where we store our neovim keybindings.

We'll first set some settings.
This will make configuring neovim nicer to type and work in.
Comments explain what each setting does.

```lua
-- ~/.config/nvim/lua/user/set.lua

-- Numbers will appear on the left side of the screen
vim.opt.nu = true
-- The line the cursor is on will show the line number we are currently on,
-- but the lines above and below our cursor will display as relative to the
-- line we are on
vim.opt.relativenumber = true

-- When you press tab, it will input 4 spaces
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Using indentation from previous lines, but considers C lang syntax
vim.opt.smartindent = true

-- Makes long lines of text extend to the next line on the screen
-- Set to false if you want to have text go off screen
vim.opt.wrap = true

-- Disables swap files, very annoying to deal with when you close Vim inelegantly
vim.opt.swapfile = false
vim.opt.backup = false

-- Disables that thing that highlights text when you search for strings
vim.opt.hlsearch = false
-- Searching jumps to the best matching string
vim.opt.incsearch = true

-- Enables 256 colors on my terminal, foot
vim.opt.termguicolors = true

-- The cursor can't scroll below 10 lines from the bottom of the screen
vim.opt.scrolloff = 10
-- Sets the time before a swap file is made after 50ms passes
vim.opt.updatetime = 50
```

Now, lets set some keybindings.
Again, all options are explained by the comments
```lua
-- ~/.config/nvim/lua/user/remap.lua

-- Leader key is basically a key that specifies "whatever key
-- comes next will do something not in the default functionality of vim"

-- Leader and leader keys
-- Leader set to space
vim.g.mapleader = " "
-- Pressing space + e to bring up a directory tree
vim.keymap.set("n", "<leader>e", vim.cmd.Ex)

-- Pressing ctrl + d will execute z + z right after, functionality stays the same
vim.keymap.set("n", "<C-d>", "<C-d>zz")
-- Same as above but with ctrl + u
vim.keymap.set("n", "<C-u>", "<C-u>zz")
-- Sets pressing n (for next) to then center the screen
vim.keymap.set("n", "n", "nzzzv")
-- Sets pressing N (for prev) to then center the screen
vim.keymap.set("n", "N", "Nzzzv")

-- Pressing space + y will copy to keyboard in normal mode
vim.keymap.set("n", "<leader>y", "\"+y")
-- Pressing space + y will copy to keyboard in visual mode
vim.keymap.set("v", "<leader>y", "\"+y")

-- Setting j and k keys to navigate through wrapped lines
vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")


-- Pressing ctrl + k will go through quickfix errors
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
-- Pressing ctrl + j will go through quickfix errors
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
-- Opens up a nvim window for a list of quickfix errors
vim.keymap.set("n", "<leader>co", "<cmd>copen<CR>zz")
-- Pressing space + k will jump to quickfix error
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
-- Pressing space + j will go through quickfix errors
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

-- Pressing space + m will make C files, only works for single C files
vim.keymap.set("n", "<leader>m", "<cmd>make %<<CR>")

-- Press space + cd and make pwd the working dir
vim.keymap.set("n", "<leader>cd", "<cmd>:cd %:p:h<CR>:pwd<CR>")
```

Neovim is almost complete now.
All we need are a few plugins that will make working on this editor easier.

## Plugins
First, we must edit `lazy.lua` to install [Lazy](https://github.com/folke/lazy.nvim), the plugin manager.
```lua
-- ~/.config/nvim/lua/user/lazy.lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("hyperboly.plugins")
```

Save the file and just to be sure, source it by typing:
> :so %

Next, we need to install some plugins in the plugins directory.
So, in the plugins directory, touch these files:
```sh
touch colorscheme.lua lsp.lua luasnip.lua telescope.lua treesitter.lua
```

We'll start with the simplest one, `colorscheme.lua`.
I am installing the [tokyonight-storm](https://github.com/folke/tokyonight.nvim) colorscheme, but catppuccin is pretty cool too.

```lua
-- colorscheme.lua
-- Installation from folke's github README
return {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
        transparent = true,
        style = "storm",
        styles = {
            italic = "true",
            sidebars = "transparent",
            floats = "transparent",
        },
    },
    config = function()
        vim.cmd[[colorscheme tokyonight-storm]]
    end,
}
```

Now, we need [telescope](https://github.com/nvim-telescope/telescope.nvim), a plugin that lets us search through files, strings, and other cool stuff.
```lua
-- telescope.lua
-- plugins/telescope.lua:
return {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.2',
    dependencies = { 'nvim-lua/plenary.nvim' },

    config = function ()
        local builtin = require('telescope.builtin')
        -- Sets keybinds for telescope
        -- Space + ff will pull up a window for you to find a file
        vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
        -- Space + fg will find files in the current git directory
        vim.keymap.set('n', '<leader>fg', builtin.git_files, {})
        -- Space + fs will find strings that match the search and jump to the file and location
        vim.keymap.set('n', '<leader>fs', function()
            builtin.grep_string({ search = vim.fn.input("Grep > ")})
        end)
    end,
}
```

Before we install a auto-completion mechanism, we'll install [treesitter](https://github.com/nvim-treesitter/nvim-treesitter/).
Treesitter does many things, but from what I understand it highlights syntax, which is useful enough for me.
```lua
return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function ()
      local configs = require("nvim-treesitter.configs")

      configs.setup({
          -- languages that treesitter will be installed for
          ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "cpp", "latex", "python", "bash", "markdown", "markdown_inline" },
          sync_install = false,
          highlight = { enable = true },
          indent = { enable = true },
      })
    end
}
```

Finally, we get to the LSP, or autocompletion mechanism.
In this part, I'll install [LSP-zero](https://github.com/VonHeikemen/lsp-zero.nvim) with lua-snippets because we'll use lua-snippets for something other than the LSP later.
```lua
-- lsp.lua
return {
  'VonHeikemen/lsp-zero.nvim',
  dependencies = {
    -- LSP Support
    {'neovim/nvim-lspconfig'},             -- Required
    {'williamboman/mason.nvim'},           -- Optional
    {'williamboman/mason-lspconfig.nvim'}, -- Optional

    -- Autocompletion
    {'hrsh7th/nvim-cmp'},     -- Required
    {'hrsh7th/cmp-nvim-lsp'}, -- Required
  },
  config = function()
    local lsp = require('lsp-zero').preset({})

    lsp.on_attach(function(client, bufnr)
    	-- see :help lsp-zero-keybindings
    	-- to learn the available actions
    	lsp.default_keymaps({buffer = bufnr})
    end)

    -- (Optional) Configure lua language server for neovim
    require('lspconfig').lua_ls.setup(lsp.nvim_lua_ls())

    lsp.setup()
    local cmp = require('cmp')
    local cmp_action = require('lsp-zero').cmp_action()

    cmp.setup({
        snippet = {
            -- REQUIRED - you must specify a snippet engine
            expand = function(args)
                vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
                require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
                -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
            end,
        },
        sources = cmp.config.sources({
            { name = 'nvim_lsp' },
            { name = 'vsnip' }, -- For vsnip users.
            { name = 'luasnip' }, -- For luasnip users.
            -- { name = 'ultisnips' }, -- For ultisnips users.
            -- { name = 'snippy' }, -- For snippy users.
        },
        {
            { name = 'buffer' },
        }),
        mapping = {
            ['<CR>'] = cmp.mapping.confirm({select = true}),
        }
    })
  end,
}
```

I won't pretend to understand the LSP-zero installation, but that's how you install it.
Next, install [luasnip](https://github.com/L3MON4D3/LuaSnip), which is also required for LSP-zero.

```lua
-- luasnip.lua
return {
	"L3MON4D3/LuaSnip",
	-- follow latest release.
	version = "v2.0.0", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
	-- install jsregexp (optional!).
	-- build = "make install_jsregexp"
    event = 'VeryLazy',
    config = function()
        require('hyperboly.snips')
        local ls = require('luasnip')

        local M = {}

        function M.expand_or_jump()
            if ls.expand_or_jumpable() then
                ls.expand_or_jump()
            end
        end

        function M.jump_next()
            if ls.jumpable(1) then
                ls.jump(1)
            end
        end

        function M.jump_prev()
            if ls.jumpable(-1) then
                ls.jump(-1)
            end
        end

        function M.change_choice()
            if ls.choice_active() then
                ls.change_choice(1)
            end
        end

        function M.reload_package(package_name)
            for module_name, _ in pairs(package.loaded) do
                if string.find(module_name, '^' .. package_name) then
                    package.loaded[module_name] = nil
                    require(module_name)
                end
            end
        end

        function M.refresh_snippets()
            ls.cleanup()
            M.reload_package('hyperboly.snips')
        end

        local set = vim.keymap.set

        local mode = { 'i', 's' }
        local normal = { 'n' }

        set(mode, '<c-i>', M.expand_or_jump)
        set(mode, '<c-n>', M.jump_prev)
        set(mode, '<c-l>', M.change_choice)
        set(normal, ',r', M.refresh_snippets)
        end
}
```

Once everything is installed, we can move on to creating configurations for LuaSnips.
Back in `~/.config/nvim/lua/user/snips.lua`, copy this in.

```lua
local ls = require("luasnip")
local fmt = require('luasnip.extras.fmt').fmt
-- some shorthands...
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

-- general func()
ls.add_snippets('c', {
    s("fn", {
        t( "// Arguments: " ),
        t({ "", "void func() {" }),
        t({ "", "\t" }),
        i(1),
        t({ "", "}" }),
    })
})

-- main
ls.add_snippets('c', {
    s("main", {
        t({ "#include <stdio.h>" }),
        t({ "", "" }),
        t({ "", "int main() {" }),
        t({ "", "\t" }),
        i(1),
        t({ "", "\treturn 0;"}),
        t({ "", "}" }),
    })
})
```

Since I'm learning the C programming language, I only have 2 snippets in here.
One that creates a `main` function while including <stdio.h> and a general function snippet.
To use these, all we have to do is create a *.c file and type "main" in insert mode, then press ctrl + i.

Neovim is now a text editor I can actually be productive in.
I don't need all the VSCode bloat like the file tree on the left or electron.
We're not done yet though, to fully complete a development environment, we are going to use tmux.

# Why Tmux?
Tmux is a "terminal multiplexer."
Basically, if you've ever tiled 2 windows together, that's what tmux is good for.
You can tile terminals together, create other windows of terminals, and they also persist through your session.
I use tmux to have a terminal at the bottom of the screen mainly for compiling programs.

## Tmux Configuration
The tmux configuration can be created in the `~/.config/tmux` directory.
```sh
mkdir -p ~/.config/tmux
touch ~/.config/tmux/tmux.conf
```

Again, I will past my configuration and use comments to explain what is happening.

```bash
# Set prefix
# The prefix acts like the leader key in vim, in this case, the prefix is ctrl+f
# All keybindings in tmux are therefore prefixed by this
set -g prefix C-f

# Prefix + r will reload the configuration without having to start a new session
bind-key r source-file ~/.config/tmux/tmux.conf \; display-message "tmux.conf reloaded."

# Setting colors
set -g default-terminal "xterm-256color"
set -g default-terminal "screen-256color"
set -as terminal-features ",xterm-256color:RGB"
set-option -ga terminal-overrides ",xterm-256color:Tc"

# Set time between a tmux command and input to terminals
set -s escape-time 0

#set -g mouse on

# Prefix + h will create/split terminals horizontally
bind-key h split-window -h
# Prefix + v will create/split terminals vertically
bind-key v split-window -v
#Sets the status bar to the top
set-option -g status-position top
```

Now that tmux is all configured, we just need one more tiny script.
Using the newly configured neovim, create a file at `~/.local/bin/dev-tmux`.
```bash
#!/usr/bin/env bash

tmux new-session \; \
    send-keys 'nvim .' C-m \; \
    split-window -v -p 30 \; \
```

This will create a tmux session with neovim on the top pane and a 30% sized terminal as the bottom pane.
As long as `~/.local/bin` is in our $PATH, we can just run `dev-tmux` and we will be in my ideal environment.

# Resources
[The Primeagen's Config](https://www.youtube.com/watch?v=w7i4amO_zaE)

[Lazy Plugins Manager Documentation](https://github.com/folke/lazy.nvim)

[Lua Snippets Docs](https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md)

[Tokyonight Theme Documentation](https://github.com/folke/tokyonight.nvim)

[Tmux Keybind Cheatsheet](https://gist.github.com/MohamedAlaa/2961058)

[LearnLinuxTV Tmux Configuration Video](https://www.youtube.com/watch?v=-f9rz7joEOA)
