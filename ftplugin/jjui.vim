" Filetype plugin for jjui buffers
if exists('b:did_ftplugin') | finish | endif
let b:did_ftplugin = 1

setlocal nobuflisted nonumber norelativenumber signcolumn=no noswapfile nowrap
nnoremap <buffer><silent> q :close<CR>

let b:undo_ftplugin = 'setl bl< nu< rnu< scl< swf< wrap<'
