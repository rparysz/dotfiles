-- Markdown is edited raw here and read in the browser — see docs/mdview.md.
--
-- render-markdown.nvim, which LazyVim's lang.markdown extra installs, is off:
-- it conceals and reflows the exact markup being edited. Treesitter still
-- colours headings, emphasis, links, fences and tables, so the buffer stays
-- readable without anything being hidden.
--
-- Everything else from the extra stays: marksman (`gd` follows a link, `gr`
-- lists backlinks), markdownlint-cli2, and markdown-preview.nvim (`<leader>cp`)
-- for a quick look at a single file.

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("markdown_raw", { clear = true }),
  pattern = { "markdown", "markdown.mdx" },
  callback = function()
    -- LazyVim sets conceallevel=2 globally. Markdown is the filetype where
    -- hiding ** and [] costs more than it saves.
    vim.opt_local.conceallevel = 0

    -- `gf` on a relative link: resolve against the buffer's own directory
    -- (nvim defaults to cwd) and let a bare name imply .md. marksman's `gd`
    -- covers the same links; this also catches plain paths.
    vim.opt_local.suffixesadd:prepend(".md")
    vim.opt_local.path:prepend(vim.fn.expand("%:p:h"))
  end,
})

return {
  { "MeanderingProgrammer/render-markdown.nvim", enabled = false },
}
