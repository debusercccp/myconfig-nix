vim.cmd([[syntax on]])
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.cursorline = true

require("lazy").setup({
  { "folke/tokyonight.nvim", lazy = false, priority = 1000, config = function() vim.cmd[[colorscheme tokyonight-storm]] end },
  { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" }, config = function() require("nvim-tree").setup({ view = { width = 30 } }) end },
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
  { "neovim/nvim-lspconfig" },
  { "stevearc/conform.nvim", opts = { formatters_by_ft = { python = { "black" }, rust = { "rustfmt" }, javascript = { "prettier" }, bash = { "shfmt" }, lua = { "stylua" } }, format_on_save = { timeout_ms = 500, lsp_fallback = true } } }
}, {
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
  checker = { enabled = false },
})

-- LSP setup con nuova API (nvim 0.11+)
local servers = { "pyright", "rust_analyzer", "clangd", "lua_ls" }
for _, srv in ipairs(servers) do
  vim.lsp.enable(srv)
end

local keymap = vim.keymap.set
keymap('n', '<leader>e', ':NvimTreeToggle<CR>')
keymap('n', '<leader>ff', ':Telescope find_files<CR>')
keymap('n', '<leader>fg', ':Telescope live_grep<CR>')
keymap({ 'n', 'v' }, '<leader>gq', function() require("conform").format() end)

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    keymap('n', 'gd', vim.lsp.buf.definition, { buffer = ev.buf })
    keymap('n', 'K', vim.lsp.buf.hover, { buffer = ev.buf })
  end,
})
