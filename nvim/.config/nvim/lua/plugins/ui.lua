return {
  {
    "folke/snacks.nvim",
    opts = {
      -- instant scrolling instead of animated
      scroll = { enabled = false },
      -- Inline images in markdown. Needs a kitty-graphics-protocol terminal
      -- AND no tmux: inside tmux, snacks' XTVERSION probe never gets an answer,
      -- so kitty goes undetected, unicode placeholders are ruled out, and the
      -- hover-float fallback draws the image at the terminal origin instead of
      -- in the float. Off in tmux; bare kitty still renders inline.
      image = {
        enabled = true,
        doc = { enabled = vim.env.TMUX == nil, inline = true, float = true },
      },
    },
  },
}
