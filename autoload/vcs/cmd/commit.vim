" vcs:cmd:commit: Do commit.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim


let s:openbuf = openbuf#new('vcs/cmd/commit', {
\ })


let s:cmd = {
\   'name': 'commit',
\ }

let s:border =
\ '-------------- This line and the following will be ignored --------------'

function! s:cmd.depends()
  return ['commit']
endfunction

function! s:cmd.execute(type, ...)
  " FIXME: abort if no files to commit.
  let self.type = a:type
  let self.files = copy(a:000)
  call s:openbuf.open('[vcs:commit]')
  let b:vcs_commit = self
  setlocal buftype=acwrite nobuflisted noswapfile
  augroup plugin-vcs-cmd-commit
    autocmd! * <buffer>
    autocmd BufWriteCmd <buffer> setlocal nomodified
    autocmd BufUnload <buffer> call b:vcs_commit.do_commit()
  augroup END

  silent % delete _
  1 put =s:border

  if has_key(a:type, 'status')
    let status = a:type.status(self.files)
    let lines = []
    for st in ['added', 'modified', 'deleted', 'conflicted', 'unknown']
      let files = filter(copy(status), 'v:val ==# st')
      if !empty(files)
        call add(lines, st)
        let lines += map(sort(keys(files)), '"  " . v:val')
      endif
    endfor
    silent $ put =[]
    silent $ put =lines
  endif

  if has_key(a:type, 'diff')
    silent $ put =[]
    silent $ put =a:type.diff(self.files)
  endif
  setlocal nomodified

  1
  setlocal filetype=vcs-commit

  return ''
endfunction

function! s:cmd.do_commit()
  let mes = split(substitute(matchstr(join(getline(1, '$'), "\n"),
  \               '^.\{-}\ze\%(\V' . escape(s:border, '\') . '\m.*\)\?$'),
  \               '^\s*\zs.\{-}\ze\s*$', '\0', ''), "\n")
  if empty(mes)
    " FIXME:
    echomsg 'vcs:commit: aborted.'
    return
  endif
  let file = tempname()
  call writefile(mes, file)
  let result = self.type.commit({'msgfile': file}, self.files)
  call delete(file)
  " FIXME: log
  echo result
endfunction

function! s:cmd.complete(args)
  return map(map(split(glob((empty(a:args) ? '' : a:args[-1]) . '*'), "\n"),
  \          'v:val . (isdirectory(v:val) ? "/" : "")'),
  \          'v:val =~ "\\s" ? "''" . v:val : v:val')
endfunction



function! vcs#cmd#commit#load()
  return copy(s:cmd)
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
