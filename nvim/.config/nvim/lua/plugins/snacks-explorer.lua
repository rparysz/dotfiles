-- Override LazyVim's <leader>fe (which <leader>e remaps to).
--
-- LazyVim's version calls Snacks.explorer() unconditionally, and
-- snacks/picker/init.lua closes an already-open picker without checking
-- focus -- so pressing it from a code window closes the tree instead of
-- jumping to it. This focuses when unfocused, and only toggles when the
-- explorer already has focus.
return {
  "folke/snacks.nvim",
  keys = {
    {
      "<leader>fe",
      function()
        local p = Snacks.picker.get({ source = "explorer" })[1]
        if not p then
          Snacks.explorer({ cwd = LazyVim.root() })
        elseif p:is_focused() then
          p:close()
        else
          p:focus()
          Snacks.explorer.reveal()
        end
      end,
      desc = "Explorer (focus, else toggle)",
    },
  },
}
