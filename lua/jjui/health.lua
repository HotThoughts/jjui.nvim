local M = {}
local utils = require('jjui.utils')
local config = require('jjui').config

function M.check()
  vim.health.start('jjui.nvim report')

  -- Check executables
  if utils.is_jj_available() then
    vim.health.ok('jj executable found')
  else
    vim.health.error('jj executable not found in PATH. Jujutsu is required.')
  end

  if utils.is_jjui_available() then
    vim.health.ok('jjui executable found')
  else
    vim.health.error('jjui executable not found in PATH. Install with `cargo install jjui`.')
  end

  if utils.is_nvr_available() then
    vim.health.ok('neovim-remote (nvr) found')
  else
    vim.health.info('neovim-remote (nvr) not found. Optional, but recommended for editing commit messages.')
  end

  -- Check configuration
  local ok, errors = utils.validate_config(config)
  if ok then
    vim.health.ok('configuration is valid')
  else
    for _, err in ipairs(errors) do
      vim.health.error(err)
    end
  end
end

return M

