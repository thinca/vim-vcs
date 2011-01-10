" The pluggable VCS integration plugin.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim


if exists('g:loaded_vcs')
  finish
endif
let g:loaded_vcs = 1


command! -nargs=+ -bang -complete=customlist,vcs#complete
\        Vcs call vcs#command(<q-args>, <bang>0)


let &cpo = s:save_cpo
unlet s:save_cpo
