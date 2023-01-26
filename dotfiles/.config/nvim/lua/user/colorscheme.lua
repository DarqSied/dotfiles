local colorscheme = "tokyonight"

require("tokyonight").setup({
  style = "storm",
  light_style = "day",
  transparent = true,
  terminal_colors = true,
})

local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
if not status_ok then
  return
end
