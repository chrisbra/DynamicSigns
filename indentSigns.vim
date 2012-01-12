	" IndentSigns.vim - Using Signs for indenting level
" ---------------------------------------------------------------
" Version:	0.1
" Authors:	Christian Brabandt <cb@256bit.org>
" Last Change: Tue, 19 July 2010 21:16:28 +0200

" Script:  
" License: VIM License
" Documentation: N/A
" GetLatestVimScripts: 

" Documentation: N/A

" Init Folkore "{{{1
if &cp || exists("g:loaded_indentSigns")
	finish
endif

let g:loaded_indentSigns   = 1
let s:keepcpo              = &cpo
set cpo&vim

" Check preconditions
fu! <sid>Check() "{{{1
	" Check for the existence of unsilent
	if exists(":unsilent")
		let s:echo_cmd='unsilent echomsg'
	else
		let s:echo_cmd='echomsg'
	endif

	if !has("signs")
		call add(s:msg, "Sign Support support not available in your Vim version.")
		call add(s:msg, "IndentSigns plugin will not be working!")
		call s:WarningMsg()
		throw 'indentSigns:abort'
	endif

	let s:sign_prefix = 99
	let s:id_hl       = {}
	let s:id_hl.Line  = "DiffAdd"
	let s:id_hl.Error = "Error"
	let s:id_hl.Check = "User1"

	" Indent Cache
	let s:indentCache = {}

	" Define Signs
	call s:DefineSigns()
endfu

fu! <sid>WarningMsg() "{{{1
	redraw!
	if !empty(s:msg)
		let msg=["IndentSigns.vim: " . s:msg[0]] + s:msg[1:]
		echohl WarningMsg
		for mess in msg
			exe s:echo_cmd "mess"
		endfor

		echohl Normal
		let v:errmsg=msg[0]
	endif
endfu

fu! <sid>Init(...) "{{{1
	" Message queue, that will be displayed.
	let s:msg  = []
	" Only check the first time this file is loaded
	" It should not be neccessary to check every time
	if !exists("s:precheck")
		call s:Check()
		let s:precheck=1
	endif
	if exists("a:1") && a:1
		call <sid>UnPlaceSigns()
	endif

	" This variable is a prefix for all placed signs.
	" This is needed, to not mess with signs placed by the user
	let s:signs={}

	" Delete previously placed signs
	let s:Signs = <sid>ReturnSigns(bufnr(''))
	"call s:UnPlaceSigns()
	call s:AuCmd(1)
endfu

fu! <sid>IndentFactor() "{{{1
	return &l:sts>0 ? &l:sts : &ts
endfu

fu! <sid>ReturnSigns(buffer) "{{{1
	redir => a 
		exe "sil sign place buffer=". a:buffer 
	redir end
	let b = split(a, "\n")[1:]
	call filter(b, 'matchstr(v:val, ''id=\zs\d\+'')')
	return b
endfu

fu! <sid>CacheIndent() "{{{1
	for i in range(1,line('$'))
		let s:indentCache[i] = (indent(i)/<sid>IndentFactor())
	endfor
	return s:indentCache
endfu

fu! <sid>AuCmd(arg) "{{{1
	if a:arg
	augroup IndentSigns
		autocmd!
		let s:verbose=0
		au BufWritePost,InsertLeave * :call s:UpdateView()
	augroup END
	else
	augroup IndentSigns
		autocmd!
	augroup END
	endif
endfu

fu! <sid>UnPlaceSigns() "{{{1
	redir => a
	silent sign place
	redir end
	let b=split(a,"\n")
	let b=filter(b, 'v:val =~ "id=".s:sign_prefix')
	let b=map(b, 'matchstr(v:val, ''id=\zs\d\+'')')
	for id in b
		exe "sign unplace" id
	endfor
endfu

fu! <sid>UnplaceSignSingle(item) "{{{1
	if a:item == 0
		return
	endif
	call setpos('.', a:item)
	" Vim errors, if the line does not contain a sign
	sil! sign unplace
endfu

fu! <sid>PlaceSigns() "{{{1
	for line in range(1,line('$'))
		let indent = indent(line)
		let div    = <sid>IndentFactor()
		if div > 0 && indent > 0 && (indent/div) != get(s:indentCache, line-1, 0)
			call <sid>UnplaceSignSingle( get(s:indentCache,(line-1),0) )
			let s:indentCache[line-1] = indent/div
			if (indent/div) < 10
				exe "sign place " s:sign_prefix . line . " line=" . line .
					\ " name=" . (indent/div) . " buffer=" . bufnr('')
			else 
				exe "sign place " s:sign_prefix . line . " line=" . line .
					\ " name=10  buffer=" . bufnr('')
			endif
		endif
	endfor
endfu


fu! <sid>DefineSigns() "{{{1
	for item in range(1,9)
		exe "silent! sign undefine " item
		exe "sign define" item	"text=".item . " texthl=" . s:id_hl.Line
	endfor
	" Indentlevel > 9
	"
	exe "sign define 10" 	"text=>".item . " texthl=" . s:id_hl.Error
	"exe "sign define IndentTabError text=E texthl=" . s:id_hl.Error . " linehl=" . s:id_hl.Error
	"exe "sign define IndentCheck text=C texthl=" . s:id_hl.Check . " linehl=" . s:id_hl.Check
endfu

fu! <sid>UpdateView() "{{{1
	if !exists("b:changes_chg_tick")
		let b:changes_chg_tick = 0
	endif
	" Only update, if there have been changes to the buffer
	if b:changes_chg_tick != b:changedtick
		call indentSigns#Run()
	endif
endfu

fu! indentSigns#Run(...) "{{{1
	try
		if exists("a:1") && a:1
			unlet! s:precheck
		endif
		call s:Init()
		catch /^indentSigns:/
		call s:WarningMsg()
		return
	endtry
	call s:PlaceSigns()
endfu

fu! <sid>CleanUp()"{{{1
	" only delete signs, that have been set by this plugin
	call s:UnPlaceSigns()
	for item in range(1,9)
		exe "sign undefine " item
	endfor
	call s:AuCmd(0)
endfu

" Define Commands "{{{1
:com! IndentSigns :call indentSigns#Run()
:com! UpdateSigns :call indentSigns#Run(1)
:com! DisableIndentSigns :call s:CleanUp()

" Restore Vim Settings "{{{1
let &cpo= s:keepcpo
unlet s:keepcpo
" Modeline "{{{1
" vim: fdm=marker fdl=0 ts=4 sts=4 com+=l\:\" fdl=0 sw=4
