return {
  -- themes to keep installed
  { "rebelot/kanagawa.nvim", priority = 1000 },
  { "folke/tokyonight.nvim", priority = 1000 },
  { "Mofiqul/vscode.nvim", priority = 1000, opts = { transparent = true } },
  { "rose-pine/neovim", name = "rose-pine", priority = 1000 },
  { "ellisonleao/gruvbox.nvim", priority = 1000 },
  { "scottmckendry/cyberdream.nvim", priority = 1000 },
  { "LunarVim/synthwave84.nvim", priority = 1000 },
  { "savq/melange-nvim", priority = 1000 },
  { "neanias/everforest-nvim", priority = 1000 },
  { "philikarus/chocolate.nvim", priority = 1000 },

  -- the active one
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "vscode",
    },
  },
}
