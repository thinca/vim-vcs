" Syntax file for vcs-commit of vcs.vim.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

if exists('b:current_syntax')
  finish
endif
syntax sync fromstart

syntax include @vcsCommitDiff syntax/diff.vim
syntax region vcsCommitIgnored start="^-\{3,}.\+-\{3,}$" end="^\%$" matchgroup=vcsCommitBorder contains=vcsCommitDiff
syntax region vcsCommitDiff start="^diff" end="^\%$" contained contains=@vcsCommitDiff

highlight default link vcsCommentBorder Special

let b:current_syntax = 'vcs-commit'
