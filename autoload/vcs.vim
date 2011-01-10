" The pluggable VCS integration plugin.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim

" Stored commands.
let s:cmds = {}

" Stored types.
let s:types = {}


" --- Interface for user. {{{1

function! vcs#vcs(cmd, ...)  " {{{2
  if !has_key(s:cmds, a:cmd)
    throw 'vcs: Command does not exist: ' . a:cmd
  endif

  let opt = {}
  let args = []

  for a in a:000
    let t = type(a)
    if t == type({})
      call extend(opt, a)
    elseif t == type([])
      let args += a
    elseif t == type('')
      let args += s:parse_argline(a)
    endif
    unlet a
  endfor

  let cmd = copy(s:cmds[a:cmd])
  let type = vcs#detect()
  if empty(type)
    throw 'vcs: This buffer is not in any repository.'
  endif
  call insert(args, copy(s:types[type[0]]))

  let res = call(cmd.execute, args, cmd)

  if type(res) == type('')
    if (has_key(opt, 'output') && opt.output ==# 'buffer') ||
    \  (exists('vcs.output[a:cmd]') && vcs.output[a:cmd] ==# 'buffer')
      " TODO: Output to buffer.
    else
      echo res
    endif
  endif
endfunction

function! vcs#detect(...)  " {{{2
  let file = fnamemodify(a:0 ? a:1 : expand('%'), ':p')
  let bufnr = bufnr(file)
  if 0 <= bufnr && type(getbufvar(bufnr, 'vcs_type')) == type([])
    return getbufvar(bufnr, 'vcs_type')
  endif
  let list = map(filter(values(s:types), 'v:val.detect(file)'), 'v:val.name')
  call setbufvar(bufnr, 'vcs_type', list)
  return list
endfunction

function! vcs#register_cmd(cmd, ...)  " {{{2
  return s:register('cmd', a:cmd, a:0 && a:1)
endfunction

function! vcs#register_type(type, ...)  " {{{2
  return s:register('type', a:type, a:0 && a:1)
endfunction

function! s:register(type, obj, overwrite)  " {{{2
  " TODO: validate
  let name = a:obj.name
  if has_key(s:{a:type}s, name) && !a:overwrite
    return 0
  endif
  let s:{a:type}s[name] = a:obj
  return 1
endfunction

function! vcs#cmds()  " {{{2
  return copy(s:cmds)
endfunction

function! vcs#types()  " {{{2
  return copy(s:types)
endfunction



" --- Functions for :Vcs command. {{{1

" function for main command.
function! vcs#command(argline, bang)  " {{{2
  try
    let arglist = s:parse_argline(a:argline)
    let params = s:parse_arglist(arglist)
    if !has_key(params, 'cmd')
      throw 'vcs: Command is not specified.'
    endif

    call vcs#vcs(params.cmd, params.args, params.gopt)
  catch /^vcs:/
    call s:echoerr(v:exception)
  endtry
endfunction

" complete function for main command.
function! vcs#complete(lead, cmd, pos)  " {{{2
  let cmd = matchstr(a:cmd, '^\v.{-}V%[cs]\s+\zs.*$')[: a:pos]
  let arglist = s:parse_argline(cmd)
  let lead = empty(arglist) ? '' : arglist[-1]
  if cmd =~# '\V' . escape(lead, '\') . '\$'
    unlet! arglist[-1]
  else
    let lead = ''
  endif
  let params = s:parse_arglist(arglist)

  let list = []
  if has_key(params, 'cmd')
    if has_key(s:cmds, params.cmd)
      let list = s:cmds[params.cmd].complete(params.args + [lead])
    endif

  else
    if lead =~ '^-'
      if lead =~ '='
        let i = stridx(a:lead, '=')
        let gopt = lead[: i - 1]
        let prefix = lead[: i]
      else
        let list = ['-type', '-output']
        let gopt = ''
      endif

    elseif 2 <= len(arglist) && arglist[-2] =~ '^-'
      let gopt = arglist[-2]
    endif

    if exists('gopt')
      if gopt == '-output'
        let list = ['buffer', 'message']
      elseif gopt == '-type'
        let prefix = lead[: strridx(lead, ',')]
        let list = keys(s:types)
      endif
    else
      let list = keys(s:cmds)
    endif

    if exists('prefix')
      call map(list, 'prefix . v:val')
    endif
  endif

  return filter(list, 'v:val =~# "^\\V" . escape(lead, "\\")')
endfunction

" Parse the command line.
" Ex.
" '-opt="foo var" commit -m "That''s a message.\n\ndetail..."'
" => ['opt=foo var', 'commit', '-m', "That's a message.\n\ndetail..."]
function! s:parse_argline(argline)  " {{{2
  let argline = a:argline
  let arglist = []
  while argline !~ '^\s*$'
    let argline = matchstr(argline, '^\s*\zs.*$')
    let arg = ''

    while argline != '' && argline !~ '^\s'
      let para = matchstr(argline, '^\v\S{-}\ze%(\\@<![[:space:]''"]|$)')
      let argline = argline[len(para) :]

      if argline =~ '^[''"]'
        let m = matchstr(argline, '^\v([''"])\zs.{-}\ze\\@<!\1')
        if m == '' && argline !~ '^\([''"]\)\1'
          " Quote is unclosed.
          let m = argline[1 :]
          let argline = ''
        else
          let argline = argline[strlen(m) + 2 :]
        endif
        let para .= m

      else
      endif
      let arg .= para
    endwhile

    " Processing backslash.
    let index = 0
    let max = len(arg)
    let newarg = ''
    while index < max
      let next = stridx(arg, '\', index)
      if next == -1
        let newarg .= arg[index :]
        break
      endif
      let newarg .= arg[index : next - 1]

      let escaped = arg[next + 1]
      if escaped == 'n'
        let newarg .= "\n"
      elseif escaped == 'r'
        let newarg .= "\r"
      else
        let newarg .= escaped
      endif
      let index = next + 2
    endwhile

    call add(arglist, newarg)
  endwhile
  return arglist
endfunction

" Parse the list of arguments.
" Ex.
" ['-opt=val', 'command', 'arg', 'list']
" => {'gopt': {'opt': 'val'}, 'cmd': 'command', 'args': ['arg', 'list']}
function! s:parse_arglist(arglist)  " {{{2
  let params = {'gopt': {}}
  let gopt = ''
  let i = 0
  for arg in a:arglist
    if gopt != ''
      let params.gopt[gopt] = arg
      let gopt = ''

    elseif arg =~ '^-'
      if gopt != ''
        let params.gopt[gopt] = 1
      endif

      let gopt = arg[1 :]
      let sep = stridx(gopt, '=')
      if 0 <= sep
        let params.gopt[gopt[: sep - 1]] = gopt[sep + 1 :]
        let gopt = ''
      endif

    else
      let params.cmd = arg
      let params.args = a:arglist[i + 1 :]
      break
    endif
    let i += 1
  endfor
  return params
endfunction

" --- Helpers for plugins. {{{1

function! vcs#system(args, ...)  " {{{2
  let args = vcs#flatten(a:args)
  let stdout = a:0 ? vimproc#system(args, a:1) : vimproc#system(args)
  return stdout
  " return {
  " \ 'result': vimproc#get_last_status(),
  " \ 'stdout': stdout,
  " \ 'stderr': vimproc#get_last_errmsg(),
  " \ }
endfunction

function! vcs#flatten(list)  " {{{2
  let list = []
  for i in a:list
    if type(i) == type([])
      let list += vcs#flatten(i)
    else
      call add(list, i)
    endif
    unlet! i
  endfor
  return list
endfunction



" --- Misc. {{{1
function! s:vcs_files(pat)  "{{{2
  return split(globpath(&runtimepath, 'autoload/vcs/' . a:pat), "\n")
endfunction

function! s:uniq(list)  "{{{2
  let d = {}
  for i in a:list
    let d[i] = 0
  endfor
  return sort(keys(d))
endfunction

function! s:echoerr(msg)  " {{{2
  echohl ErrorMsg
  for line in split(a:msg, "\n")
    echomsg line
  endfor
  echohl None
endfunction

" --- Register. {{{1
" FIXME: lazy?
function! s:register_defaults(kind)
  for name in map(s:vcs_files(a:kind . '/*.vim'),
  \               'fnamemodify(v:val, ":t:r")')
    try
      call s:register(a:kind, vcs#{a:kind}#{name}#load(), 1)
    catch /:E\%(117\|716\):/
    endtry
  endfor
endfunction

call s:register_defaults('cmd')
call s:register_defaults('type')


function! vcs#_d()
  return {'type': s:types, 'cmd': s:cmds}
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: fdm=marker
