" IndentSigns.vim - Using Signs 
" -----------------------------
" Version:	   0.1
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Fri, 13 Jan 2012 21:30:54 +0100
"
" Script: 
" Copyright:   (c) 2009, 2010, 2011, 2012  by Christian Brabandt
"			   The VIM LICENSE applies to histwin.vim 
"			   (see |copyright|) except use "ft_improved.vim" 
"			   instead of "Vim".
"			   No warranty, express or implied.
"	 *** ***   Use At-Your-Own-Risk!   *** ***
" GetLatestVimScripts: 3877 2 :AutoInstall: ft_improved.vim
"
" Init: {{{1
let s:cpo= &cpo
if exists("g:loaded_Signs") || &cp
  finish
endif
set cpo&vim
let g:loaded_Signs = 1

" ----------------------------------------------------------------------------
" Define the Mapping: "{{{2

" marks:
"noremap m call Signs#DoMarks()<cr>
" Don't do this!
"nnoremap <C-L> :call Signs#UpdateWindowSigns()<cr>

" Define Commands "{{{1
:com! Signs :call Signs#Run()
:com! UpdateSigns :call Signs#Run(1)
:com! DisableSigns :call Signs#CleanUp()
:com! -bang SignQF :call Signs#SignsQFList(<bang>0)
:com! -nargs=1 SignExpression :let g:Signs_Hook=<q-args>|
		\call Signs#Run(1)

:com! SignDiff :let g:Signs_Diff=1|
		\ call Signs#Run(1)

if  exists("g:Signs_QFList") && g:Signs_QFList
	augroup Signs
			autocmd!
			au QuickFixCmdPost * :call Signs#QFSigns()
	augroup END
endif

" Restore: "{{{1
let &cpo=s:cpo
unlet s:cpo
" vim: ts=4 sts=4 fdm=marker com+=l\:\"
