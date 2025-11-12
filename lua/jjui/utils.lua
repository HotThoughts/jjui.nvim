-- Utility functions for jjui.nvim

local M = { visited_repos = {} }

-- Get the git/jj repository root directory
function M.get_repo_root(path)
  local jj = vim.fn.finddir('.jj', (path or vim.fn.getcwd()) .. ';')
  if jj ~= '' then
    return vim.fn.fnamemodify(jj, ':h')
  end
  local git = vim.fn.finddir('.git', (path or vim.fn.getcwd()) .. ';')
  return git ~= '' and vim.fn.fnamemodify(git, ':h') or nil
end

-- Track current project root directory
function M.project_root_dir()
  local repo_root =
    M.get_repo_root(vim.fn.fnamemodify(vim.fn.expand('%:p') ~= '' and vim.fn.expand('%:p') or vim.fn.getcwd(), ':h'))
  if repo_root then
    for _, repo in ipairs(M.visited_repos) do
      if repo.path == repo_root then
        return repo_root
      end
    end
    table.insert(
      M.visited_repos,
      { path = repo_root, name = vim.fn.fnamemodify(repo_root, ':t'), last_visited = os.time() }
    )
  end
  return repo_root
end

-- Check executables (inlined as closures for efficiency)
M.is_jjui_available = function()
  return vim.fn.executable('jjui') == 1
end
M.is_jj_available = function()
  return vim.fn.executable('jj') == 1
end
M.is_nvr_available = function()
  return vim.fn.executable('nvr') == 1
end

-- Get neovim server address (prioritize NVIM_LISTEN_ADDRESS fallback pattern)
M.get_nvim_server_address = function()
  return vim.env.NVIM or vim.env.NVIM_LISTEN_ADDRESS or '/tmp/nvim-jjui-' .. vim.fn.getpid() .. '.sock'
end

-- Setup environment for jjui to use neovim as editor
function M.setup_editor_env()
  local env = {}
  if M.is_nvr_available() and vim.g.jjui_use_neovim_remote ~= 0 then
    local ed = "nvr -cc split --remote-wait +'set bufhidden=wipe'"
    env.EDITOR, env.VISUAL, env.GIT_EDITOR = ed, ed, ed
  elseif vim.v.servername ~= '' then
    local ed = 'nvim --server ' .. M.get_nvim_server_address() .. ' --remote-tab'
    env.EDITOR, env.VISUAL = ed, ed
  end
  return env
end

-- Validate configuration
function M.validate_config(config)
  local errors = {}
  if not M.is_jjui_available() then
    errors[#errors + 1] = 'jjui is not installed or not in PATH'
  end
  if not M.is_jj_available() then
    errors[#errors + 1] = 'jj is not installed or not in PATH'
  end

  local factor = config.floating_window_scaling_factor
  if factor and (type(factor) ~= 'number' or factor <= 0 or factor > 1) then
    errors[#errors + 1] = 'floating_window_scaling_factor must be a number between 0 and 1'
  end

  local chars = config.floating_window_border_chars
  if chars and (type(chars) ~= 'table' or #chars ~= 8) then
    errors[#errors + 1] = 'floating_window_border_chars must be a table with 8 elements'
  end

  return #errors == 0, errors
end

-- Get repository information
function M.get_repo_info(path)
  local root = M.get_repo_root(path)
  if not root then
    return nil
  end

  local typ = vim.fn.isdirectory(root .. '/.jj') == 1 and 'jj'
    or (vim.fn.isdirectory(root .. '/.git') == 1 and 'git' or nil)
  return { root = root, name = vim.fn.fnamemodify(root, ':t'), type = typ }
end

return M
