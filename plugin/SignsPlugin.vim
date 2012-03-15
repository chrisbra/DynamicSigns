" DynamicSigns.vim - Using Signs 
" -----------------------------
" Version:	   0.2
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Thu, 15 Mar 2012 23:37:37 +0100
" Script: 
" Copyright:   (c) 2009, 2010, 2011, 2012  by Christian Brabandt
"			   The VIM LICENSE applies to histwin.vim 
"			   (see |copyright|) except use "ft_improved.vim" 
"			   instead of "Vim".
"			   No warranty, express or implied.
"	 *** ***   Use At-Your-Own-Risk!   *** ***
" GetLatestVimScripts: 3877 3 :AutoInstall: ft_improved.vim
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
"noremap m call DynamicSigns#DoMarks()<cr>
" Don't do this!
"nnoremap <C-L> :call Signs#UpdateWindowSigns()<cr>

" Map m key?
"nnoremap <silent> <expr> <Plug>DynamicSignsMapBookmark DynamicSigns#MapBookmark()
call DynamicSigns#MapKey()

" Define Commands "{{{1
:com! Signs :call DynamicSigns#Run()
:com! UpdateSigns :call DynamicSigns#Run(1)
:com! DisableSigns :call DynamicSigns#CleanUp()
:com! -bang SignQF :call DynamicSigns#SignsQFList(<bang>0)
:com! -nargs=1 SignExpression
		\ :call DynamicSigns#PrepareSignExpression(<q-args>)

:com! SignDiff :let g:Signs_Diff=1|
		\ call DynamicSigns#Run(1)

if  exists("g:Signs_QFList") && g:Signs_QFList
	" prevent loading autoload file too early
	call <sid>ActivateAuCmds()
endif

fu! <sid>ActivateAuCmds()
	augroup Signs
			autocmd!
			au QuickFixCmdPost * :call DynamicSigns#QFSigns()
	augroup END
endfu

" Restore: "{{{1
let &cpo=s:cpo
unlet s:cpo
" vim: ts=4 sts=4 fdm=marker com+=l\:\"
