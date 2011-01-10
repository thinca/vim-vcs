" vcs:cmd:root: Get root of working directory.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim


let s:cmd = {}
let s:cmd.name = 'root'



function! s:cmd.depends()
  return ['root']
endfunction



function! s:cmd.execute(type, ...)
  let file = a:0 ? fnamemodify(a:1, ':p') : expand('%:p')
  " TODO: cache
  return a:type.root(file)
endfunction




function! vcs#cmd#root#load()
  return copy(s:cmd)
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
