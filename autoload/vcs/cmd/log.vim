" vcs:cmd:log: Show repository's log.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim


let s:openbuf = openbuf#new('vcs/cmd/log', {
\ })


let s:cmd = {
\   'name': 'log',
\ }

function! s:cmd.depends()
  return ['log']
endfunction

function! s:cmd.execute(type)
  let log = call(a:type.log, a:000, a:type)
  call s:openbuf.open('[vcs:diff]')
  setlocal noreadonly
  silent % delete _
  silent 1 put =log
  silent 1 delete _
  setlocal buftype=nofile readonly
endfunction



function! vcs#cmd#log#load()
  return copy(s:cmd)
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
