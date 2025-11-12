" jjui.nvim - Vim commands for jjui integration
if exists('g:loaded_jjui') | finish | endif
let g:loaded_jjui = 1

com! -nargs=* JJUI lua require('jjui').jjui(<q-args>)
com! -nargs=0 JJUICurrentFile lua require('jjui').jjui_current_file()
com! -nargs=0 JJUIFilter lua require('jjui').jjui_filter()
com! -nargs=0 JJUIFilterCurrentFile lua require('jjui').jjui_filter_current_file()
com! -nargs=0 JJConfig lua require('jjui').jjui_config()
com! -nargs=0 JJRepos lua require('telescope').extensions.jj.jjui()

nn <silent><Plug>(JJUI) :JJUI<CR>
nn <silent><Plug>(JJUICurrentFile) :JJUICurrentFile<CR>
nn <silent><Plug>(JJUIFilter) :JJUIFilter<CR>
nn <silent><Plug>(JJUIFilterCurrentFile) :JJUIFilterCurrentFile<CR>
nn <silent><Plug>(JJConfig) :JJConfig<CR>
nn <silent><Plug>(JJRepos) :JJRepos<CR>

if !hasmapto('<Plug>(JJUI)') && empty(maparg('<leader>jj','n')) | nmap <leader>jj <Plug>(JJUI) | endif
