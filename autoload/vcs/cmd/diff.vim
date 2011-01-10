" vcs:cmd:diff: Show changes between commits.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim


let s:openbuf = openbuf#new('vcs/cmd/diff', {
\ })


let s:cmd = {
\   'name': 'diff',
\ }

function! s:cmd.depends()
  return ['diff']
endfunction

function! s:cmd.execute(type, ...)
  let diff = call(a:type.diff, a:000, a:type)
  if diff !~ '\S'
    echohl WarningMsg
    echomsg 'vcs: diff: no diff.'
    echohl NONE
    return
  endif
  call s:openbuf.open('[vcs:diff]')
  setlocal noreadonly
  silent % delete _
  silent 1 put =diff
  silent 1 delete _
  setlocal filetype=diff buftype=nofile readonly
endfunction



function! vcs#cmd#diff#load()
  return copy(s:cmd)
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
