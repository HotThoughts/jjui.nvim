-- jjui.nvim - Neovim plugin for jjui integration
-- Similar to lazygit.nvim but for jj version control

if not pcall(require, 'plenary') then
  vim.notify('jjui.nvim requires plenary.nvim to be installed', vim.log.levels.ERROR)
  return {}
end

local M = {
  config = {
    floating_window_winblend = 0,
    floating_window_scaling_factor = 0.85,
    floating_window_border = 'rounded',
    floating_window_use_plenary = 1,
    use_neovim_remote = 1,
    use_custom_config_file_path = 0,
    config_file_path = '',
    on_exit_callback = nil,
  },
}

local utils = require('jjui.utils')
local jjui_buf, jjui_win, prev_win

-- Get window dimensions (inlined for hot path)
local function get_floating_window_size()
  local f, w, h = M.config.floating_window_scaling_factor, vim.o.columns, vim.o.lines
  local ww, wh = math.floor(w * f), math.floor(h * f) - 2
  return { width = ww, height = wh, row = math.floor((h - wh) / 2) - 1, col = math.floor((w - ww) / 2) }
end

-- Create floating window (optimized API batching)
local function create_floating_window()
  local size = get_floating_window_size()

  if not (jjui_buf and vim.api.nvim_buf_is_valid(jjui_buf)) then
    jjui_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(jjui_buf, 'bufhidden', 'hide')
    vim.api.nvim_buf_set_option(jjui_buf, 'filetype', 'jjui')
  end

  jjui_win = vim.api.nvim_open_win(jjui_buf, true, {
    relative = 'editor',
    width = size.width,
    height = size.height,
    row = size.row,
    col = size.col,
    style = 'minimal',
    border = M.config.floating_window_border,
  })

  vim.api.nvim_win_set_option(jjui_win, 'winblend', M.config.floating_window_winblend)
  vim.api.nvim_win_set_option(jjui_win, 'winhighlight', 'Normal:JjuiFloat,NormalFloat:JjuiFloat')
end

-- Close jjui window
local function close_jjui_window()
  if jjui_win and vim.api.nvim_win_is_valid(jjui_win) then
    vim.api.nvim_win_close(jjui_win, true)
  end
  jjui_win = nil

  if prev_win and vim.api.nvim_win_is_valid(prev_win) then
    vim.api.nvim_set_current_win(prev_win)
  end
  if M.config.on_exit_callback then
    M.config.on_exit_callback()
  end
end

-- Build jjui command with optional arguments
local function build_jjui_command(args)
  local cmd = 'jjui'

  if M.config.use_custom_config_file_path == 1 and M.config.config_file_path ~= '' then
    local paths = type(M.config.config_file_path) == 'table' and M.config.config_file_path
      or { M.config.config_file_path }
    for _, path in ipairs(paths) do
      cmd = cmd .. ' --config-file ' .. path
    end
  end

  return args and (cmd .. ' ' .. args) or cmd
end

-- Open jjui in a floating window
function M.jjui(args)
  local repo_root = utils.get_repo_root()
  if repo_root then
    local found = false
    for _, repo in ipairs(utils.visited_repos) do
      if repo.path == repo_root then
        repo.last_visited = os.time()
        found = true
        break
      end
    end
    if not found then
      table.insert(
        utils.visited_repos,
        { path = repo_root, name = vim.fn.fnamemodify(repo_root, ':t'), last_visited = os.time() }
      )
    end
  end

  prev_win = vim.api.nvim_get_current_win()

  -- Toggle if already open
  if jjui_win and vim.api.nvim_win_is_valid(jjui_win) then
    close_jjui_window()
    return
  end

  -- Force fresh buffer to avoid "modified buffer" error
  if jjui_buf and vim.api.nvim_buf_is_valid(jjui_buf) then
    vim.api.nvim_buf_delete(jjui_buf, { force = true })
  end
  jjui_buf = nil

  create_floating_window()

  vim.fn.termopen(build_jjui_command(args), { on_exit = close_jjui_window })
  vim.cmd('startinsert')

  vim.api.nvim_create_autocmd('BufLeave', { buffer = jjui_buf, callback = close_jjui_window, once = true })

  vim.api.nvim_create_autocmd('VimResized', {
    callback = function()
      if jjui_win and vim.api.nvim_win_is_valid(jjui_win) then
        local size = get_floating_window_size()
        vim.api.nvim_win_set_config(jjui_win, {
          relative = 'editor',
          width = size.width,
          height = size.height,
          row = size.row,
          col = size.col,
        })
      end
    end,
    group = vim.api.nvim_create_augroup('JjuiResize', { clear = true }),
  })
end

-- Open jjui for current file's repository
function M.jjui_current_file()
  local orig_dir = vim.fn.getcwd()
  vim.cmd('cd ' .. vim.fn.expand('%:p:h'))

  M.jjui()

  local orig_cb = M.config.on_exit_callback
  M.config.on_exit_callback = function()
    vim.cmd('cd ' .. orig_dir)
    if orig_cb then
      orig_cb()
    end
  end
end

-- Open jjui filter (for recent commits)
M.jjui_filter = function()
  M.jjui('-n 100')
end

-- Open jjui filter for current file
function M.jjui_filter_current_file()
  local file = vim.fn.expand('%:p')
  if file == '' then
    vim.notify('No file open to filter', vim.log.levels.WARN)
    return
  end

  if not utils.get_repo_root() then
    vim.notify('Not in a jj repository', vim.log.levels.WARN)
    return
  end

  M.jjui('-r "files(' .. vim.fn.shellescape(vim.fn.fnamemodify(file, ':.')) .. ')"')
end

-- Open jjui config
function M.jjui_config()
  local cfg = vim.fn.expand('~/.config/jjui/config.toml')
  vim.fn.mkdir(vim.fn.fnamemodify(cfg, ':h'), 'p')
  vim.cmd('edit ' .. cfg)
end

-- Setup function
function M.setup(opts)
  if opts then
    for k, v in pairs(opts) do
      M.config[k] = v
    end
  end

  -- Apply vim.g variables if they exist (batch processing)
  for _, var in ipairs({
    'jjui_floating_window_winblend',
    'jjui_floating_window_scaling_factor',
    'jjui_floating_window_border',
    'jjui_floating_window_use_plenary',
    'jjui_use_neovim_remote',
    'jjui_use_custom_config_file_path',
    'jjui_config_file_path',
    'jjui_on_exit_callback',
  }) do
    if vim.g[var] ~= nil then
      M.config[var:gsub('^jjui_', '')] = vim.g[var]
    end
  end

  -- Set up highlight groups with transparent background
  local function set_highlight()
    local bg = vim.api.nvim_get_hl(0, { name = 'Normal' }).bg
    vim.api.nvim_set_hl(0, 'JjuiFloat', { bg = bg and ('#%06x'):format(bg) or 'NONE', default = false })
  end

  set_highlight()
  vim.api.nvim_set_hl(0, 'JjuiBorder', { link = 'FloatBorder', default = true })
  vim.api.nvim_create_autocmd('ColorScheme', { callback = set_highlight })
end

return M
