-- markdownlint-cli2 only discovers config files between the linted file and the
-- current working directory, so a config in $HOME is never found when nvim is
-- opened inside a project. Pass it explicitly instead.
return {
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      local cfg = vim.fn.expand("~/.markdownlint-cli2.yaml")
      if vim.uv.fs_stat(cfg) then
        local lint = require("lint")
        local ml = lint.linters["markdownlint-cli2"]
        if ml then
          ml.args = { "--config", cfg, "-" }
        end
      end
      return opts
    end,
  },
}
