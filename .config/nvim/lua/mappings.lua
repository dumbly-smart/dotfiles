require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Move to beginning/end of line (Alt+h / Alt+l)
map('n', '<A-h>', '^', opts)
map('n', '<A-l>', '$', opts)
map('i', '<A-h>', '<Esc>^i', opts)
map('i', '<A-l>', '<Esc>$a', opts)
map('v', '<A-h>', '^', opts)
map('v', '<A-l>', '$', opts)

-- Select everything (Alt+a)
map('n', '<A-a>', 'ggVG', opts)
map('i', '<A-a>', '<Esc>ggVG', opts)
map('v', '<A-a>', 'ggVG', opts)

