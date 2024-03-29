-- vim.o - global options
-- vim.wo - local to window

vim.g.mapleader = ' '
vim.g.ayucolor = "mirage"

local set = vim.o

-- require('monokai').setup { palette = require('monokai').soda }


vim.cmd("colorscheme NeoSolarized")

set.expandtab = true
set.smartindent = true
set.shiftwidth = 2
set.softtabstop = 2
set.termguicolors = true
set.number = true
set.relativenumber = true
set.swapfile = false
set.hidden = true
-- set.guicursor = ""
set.hlsearch = false
set.mouse = 'a'
set.incsearch = true
set.wrap = false
set.scrolloff = 8
set.syntax = 'on'
vim.cmd(":set clipboard=unnamedplus")
