-- Luacheck configuration for jjui.nvim
-- https://luacheck.readthedocs.io/en/stable/config.html

-- Set the standard globals
std = "lua51+luajit"

-- Global variables (Neovim API)
globals = {
  "vim",
}

-- Read-only globals
read_globals = {
  "vim",
}

-- Exclude some warnings
ignore = {
  "631",  -- Line too long (handled by StyLua)
  "212",  -- Unused argument (common in callbacks)
}

-- Maximum line length (should match StyLua config)
max_line_length = 120

-- Don't report unused arguments in functions
unused_args = false

-- Files to exclude
exclude_files = {
  ".luacheckrc",
}
