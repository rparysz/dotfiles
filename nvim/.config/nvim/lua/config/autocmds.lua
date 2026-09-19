-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Auto-reload buffers when the underlying file changes on disk (e.g. edited by
-- another tool). LazyVim already sets `autoread` and checks on FocusGained; this
-- adds a check while idle in the buffer so it reloads without leaving the window.
-- Safe: `autoread` only reloads buffers with NO unsaved changes — if you've
-- edited the buffer, you get the usual "file changed" prompt instead.
local reload = vim.api.nvim_create_augroup("auto_reload_changed_files", { clear = true })

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = reload,
  pattern = "*",
  callback = function()
    if vim.fn.mode() ~= "c" and vim.fn.expand("%") ~= "" then
      vim.cmd("checktime")
    end
  end,
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = reload,
  callback = function()
    vim.notify("File changed on disk — buffer reloaded", vim.log.levels.INFO)
  end,
})
