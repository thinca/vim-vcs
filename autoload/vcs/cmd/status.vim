" vcs:cmd:status: Show the status of files.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim


let s:cmd = {
\   'name': 'status',
\ }

function! s:cmd.depends()
  return ['status', 'root']
endfunction

function! s:cmd.execute(type, ...)
  let file = a:0 ? a:1 : expand('%:p')
  let status = a:type.status(file)
  let lines = []
  for st in ['added', 'modified', 'deleted', 'conflicted', 'unknown']
    let files = filter(copy(status), 'v:val ==# st')
    if !empty(files)
      call add(lines, st)
      let lines += map(keys(files), '"  " . v:val')
    endif
  endfor
  return join(lines, "\n")
endfunction



function! vcs#cmd#status#load()
  return copy(s:cmd)
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
