local options = {
  backup = false,
    exrc = true,
    hidden = true,
    completeopt = { "menuone", "noinsert", "noselect" },
    conceallevel = 0,
    fileencoding = "utf-8",
    hlsearch = false,
    incsearch = true,
    ignorecase = true,
    mouse = "a",
    pumheight = 10,
    showmode = false,
    showtabline = 2,
    smartcase = true,
    errorbells = false,
    smartindent = true,
    splitbelow = true,
    splitright = true,
    swapfile = false,
    termguicolors = true,
    timeoutlen = 100,
    undofile = true,
    cmdheight = 1,
    updatetime = 300,
    writebackup = false,
    expandtab = true,
    shiftwidth = 4,
    tabstop = 4,
    softtabstop = 4,
    cursorline = true,
    number = true,
    relativenumber = true,
    numberwidth = 4,
    signcolumn = "no",
    wrap = false,
    scrolloff = 10,
    sidescrolloff = 5,
    guifont = "Hack:h18",
}

vim.opt.shortmess:append "c"

for k, v in pairs(options) do
  vim.opt[k] = v
end

vim.cmd "set whichwrap+=<,>,[,],h,l"
vim.cmd [[set iskeyword+=-]]
vim.cmd [[set formatoptions-=cro]] -- TODO: this doesn't seem to work

-- Colorscheme settings
vim.g.neon_style = "dark"
vim.g.neon_bold = true
vim.g.neon_transparent = true
vim.g.neon_italic_comment = true

