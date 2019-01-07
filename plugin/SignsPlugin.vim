" DynamicSigns.vim - Using Signs 
" -----------------------------
" Version:	   0.1
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Thu, 15 Mar 2012 23:37:37 +0100
" Script:      https://www.vim.org/scripts/script.php?script_id=3965
" Copyright:   (c) 2009 - 2019  by Christian Brabandt
"			   The VIM LICENSE applies to histwin.vim 
"			   (see |copyright|) except use "DynamicSigns" 
"			   instead of "Vim".
"			   No warranty, express or implied.
"	 *** ***   Use At-Your-Own-Risk!   *** ***
" GetLatestVimScripts: 3965 1 :AutoInstall: DynamicSigns.vim
"
" Init: {{{1
let s:cpo= &cpo
if exists("g:loaded_Signs") || &cp
  finish
endif
set cpo&vim
let g:loaded_Signs = 1

fu! <sid>ActivateAuCmds()
	augroup Signs
			autocmd!
			au QuickFixCmdPost * :call DynamicSigns#QFSigns()
	augroup END
endfu

" ----------------------------------------------------------------------------
" Define the Mapping: "{{{2

" marks:
nnoremap <silent> <expr> <Plug>DynamicSignsMapBookmark DynamicSigns#MapBookmark()
if !hasmapto('<Plug>DynamicSignsMapBookmark', 'n') && empty(maparg('m', 'n'))
    nmap <silent> m <Plug>DynamicSignsMapBookmark
endif

" Define Commands "{{{1
:com! Signs :call DynamicSigns#Run()
:com! UpdateSigns :call DynamicSigns#Update()
:com! DisableSigns :call DynamicSigns#CleanUp()
:com! -bang SignQF :call DynamicSigns#SignsQFList(<bang>0)
:com! -nargs=1 SignExpression
		\ :call DynamicSigns#PrepareSignExpression(<q-args>)
:com! SignListExpression :echo get(w:, 'Signs_Hook', '<None>')

:com! SignDiff :let g:Signs_Diff=1| call DynamicSigns#Run(1)

if get(g:, "Signs_QFList", 0)
	" prevent loading autoload file too early
	call <sid>ActivateAuCmds()
endif

if get(g:, "g:Signs_Scrollbar", 0)
	call DynamicSigns#UpdateScrollbarSigns()
endif

if (get(g:, "Signs_MixedIndentation", 0) ||
		\ get(g:, "Signs_IndentationLevel, ", 0) ||
		\ get(g:, "Signs_Bookmarks, ", 0)  ||
		\ get(g:, "Signs_Alternate, ", 0)  ||
		\ get(g:, "Signs_Hook, ", 0)	   ||
		\ get(g:, "Signs_QFList, ", 0)	   ||
		\ get(g:, "Signs_Diff, ", 0))
	call DynamicSigns#Update()
endif

" Restore: "{{{1
let &cpo=s:cpo
unlet s:cpo
" vim: ts=4 sts=4 fdm=marker com+=l\:\"
