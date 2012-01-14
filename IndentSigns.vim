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
if &cp || exists("g:loaded_IndentSigns")
	finish
endif

let g:loaded_IndentSigns   = 1
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
		call <sid>WarningMsg()
		throw 'IndentSigns:abort'
	endif

	let s:sign_prefix = 99
	let s:id_hl       = {}
	let s:id_hl.Line  = "DiffAdd"
	let s:id_hl.Error = "Error"
	let s:id_hl.Check = "User1"

	" Define Signs
	call <sid>DefineSigns()
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
	
	" Setup configuration variables:
	let s:MixedIndentation = exists("g:IndentSigns_MixedIndentation") ? 
				\ g:IndentSigns_MixedIndentation : 1

	let s:IndentationLevel = exists("g:IndentSigns_IndentationLevel") ?
					\ g:IndentSigns_IndentationLevel : 1

	let s:BookmarkSigns	   = exists("g:IndentSigns_Bookmarks") ? 
					\ g:IndentSigns_Bookmarks : 1

	let s:Bookmarks = split("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", '\zs')

	let s:SignHook = exists("g:IndentSigns_Hook") ? g:IndentSigns_Hook : ''

	" Only check the first time this file is loaded
	" It should not be neccessary to check every time
	if !exists("s:precheck") || (exists("a:1") && a:1)
		call <sid>Check()
		call <sid>UnPlaceSigns()
		let s:precheck=1
	endif
	" Indent Cache
	if !exists("b:indentCache")
		let b:indentCache = {}
	endif

	" This variable is a prefix for all placed signs.
	" This is needed, to not mess with signs placed by the user
	let s:signs={}

	let s:Signs = <sid>ReturnSigns(bufnr(''))
	call <sid>AuCmd(1)
endfu

fu! <sid>IndentFactor() "{{{1
	return &l:sts>0 ? &l:sts : &ts
endfu

fu! <sid>ReturnSigns(buffer) "{{{1
	redir => a 
		exe "sil sign place buffer=". a:buffer 
	redir end
	let b = split(a, "\n")[2:]
	" Remove old deleted Signs
	call <sid>RemoveDeletedSigns(filter(copy(b), 'matchstr(v:val, ''deleted'')'))
	call filter(b, 'matchstr(v:val, ''id=\zs\d\+'')')
	return b
endfu

fu! <sid>RemoveDeletedSigns(list)
	for sign in a:list
		let id=matchstr(sign, 'id=\zs\d\+')
		exe "sil sign unplace" id "buffer=". bufnr('')
	endfor
endfu

fu! <sid>CacheIndent() "{{{1
	for i in range(1,line('$'))
		let b:indentCache[i] = (indent(i)/<sid>IndentFactor())
	endfor
	return b:indentCache
endfu

fu! <sid>AuCmd(arg) "{{{1
	if a:arg
	augroup IndentSigns
		autocmd!
		let s:verbose=0
		au BufWritePost,InsertLeave * :call <sid>UpdateView()
	augroup END
	else
	augroup IndentSigns
		autocmd!
	augroup END
	augroup! IndentSigns
	endif
endfu

fu! <sid>UnPlaceSigns() "{{{1
	redir => a
	exe "silent sign place buffer=".bufnr('')
	redir end
	let b=split(a,"\n")[1:]
	if empty(b)
		return
	endif
	let b=filter(b, 'v:val =~ "id=".s:sign_prefix')
	let b=map(b, 'matchstr(v:val, ''id=\zs\d\+'')')
	for id in b
		exe "sign unplace" id
	endfor
endfu

fu! <sid>UnplaceSignSingle(item) "{{{1
	if a:item < 0
		return
	endif
	call setpos('.', a:item)
	" Vim errors, if the line does not contain a sign
	sil! sign unplace
endfu

fu! <sid>UpdateWindowSigns() "{{{1
	" Only update all signs in the current window viewport
	try
		call <sid>Init()
	catch
		call <sid>WarningMsg()
		return
	endtry
	call <sid>PlaceSigns(line('w0'), line('w$'))
	" Redraw Screen
	exe "norm! \<C-L>"
endfu

fu! <sid>GetMarks() "{{{1
	let marks={}
	let t = []
	for mark in s:Bookmarks
		let t = getpos("'".mark)
		if t[1] > 0
			let marks[t[1]] = mark
		endif
	endfor
	return marks
endfu

fu! <sid>PlaceSigns(...) "{{{1
	let _a = winsaveview()
	let PlacedSigns = copy(s:Signs)
	let first = !exists("a:1") ? 1 : a:1
	let last = !exists("a:2") ? line('$') : a:2
	let did_place_sign=0
	for line in range(first, last)

		" Custom Sign Hooks "{{{3
		if exists("s:SignHook") && !empty(s:SignHook)
			try
				let oldSign = match(PlacedSigns, 'line='.line. '\D.*name=IndentCustom')
				let expr = substitute(s:SignHook, 'v:lnum', line, 'g')
				if oldSign >= 0
					continue
				endif
				if eval(expr)
					exe "sign place " s:sign_prefix . line . " line=" . line .
						\ " name=IndentCustom buffer=" . bufnr('')
					continue
				elseif oldSign >= 0
					" Custom Sign no longer needed, remove it
					call <sid>UnplaceSignSingle(oldSign)
				endif
			catch
				echo "Error: " v:exception
			endtry
		endif

		" Place signs for bookmarks "{{{3
		if exists("s:BookmarkSigns") &&
					\ s:BookmarkSigns == 1
			let oldSign = match(PlacedSigns, 'line='.line. '\D.*name=IndentBookmark')
			let bookmarks = <sid>GetMarks()
			for mark in sort(keys(bookmarks))
				if mark == line
					exe "sign place " s:sign_prefix . line . " line=" . line .
						\ " name=IndentBookmark". bookmarks[mark] . " buffer=" . bufnr('')
					let did_place_sign = 1
					break
				elseif mark > line
					break
				endif
			endfor
			if oldSign >= 0
				" Bookmark Sign no longer needed, remove it
				call <sid>UnplaceSignSingle(oldSign)
			endif
			if did_place_sign
				continue
			endif
		endif

		" Place signs for mixed indentation rules "{{{3
		if exists("s:MixedIndentation") &&
					\ s:MixedIndentation == 1

			let a=matchstr(getline(line), '^\s\+\ze\S')
			let oldSign = match(PlacedSigns, 'line='.line. '.*name=IndentWSError')
			if match(a, '\%(\t \)\|\%( \t\)') > -1
				\ && s:MixedIndentation
				if oldSign >= 0
					continue
				endif
				exe "sign place " s:sign_prefix . line . " line=" . line .
					\ " name=IndentWSError buffer=" . bufnr('')
				continue
			elseif oldSign >= 0
				" No more wrong indentation, remove sign
				call <sid>UnplaceSignSingle(oldSign)
			endif

		endif

		if exists("s:_IndentationLevel") &&
					\ s:_IndentationLevel == 1
			" Place signs for Indentation Level {{{3
			let indent = indent(line)
			let div    = <sid>IndentFactor()

			if div > 0 && indent > 0 && (indent/div) != get(b:indentCache, line-1, -1)
				call <sid>UnplaceSignSingle( get(b:indentCache,(line-1),-1) )
				let b:indentCache[line-1] = indent/div
				if (indent/div) < 10
					exe "sign place " s:sign_prefix . line . " line=" . line .
						\ " name=" . (indent/div) . " buffer=" . bufnr('')
				else 
					exe "sign place " s:sign_prefix . line . " line=" . line .
						\ " name=10  buffer=" . bufnr('')
				endif
				continue
			endif
		endif "}}}3

	endfor
	if _a.lnum != getpos('.')[1]
		call winrestview(_a)
	endif
endfu


fu! <sid>DefineSigns() "{{{1
	for item in range(1,9)
		exe "silent! sign undefine " item
		exe "sign define" item	"text=".item . " texthl=" . s:id_hl.Line
	endfor

	" Indentlevel > 9
	silent! sign undefine 10
	exe "sign define 10" 	"text=>".item . " texthl=" . s:id_hl.Error

	" Mixed Indentation Error
	silent! sign undefine IndentWSError
	exe "sign define IndentWSError text=X texthl=" . s:id_hl.Error . 
		\ " linehl=" . s:id_hl.Error
	"exe "sign define IndentCheck text=C texthl=" . s:id_hl.Check . " linehl=" . s:id_hl.Check
	"
	" Custom Signs Hooks
	silent! sign undefine IndentCustom
	exe "sign define IndentCustom text=C texthl=" . s:id_hl.Error

	" Bookmark Signs
	for item in s:Bookmarks
		exe "silent! sign undefine IndentBookmark".item
		exe "sign define IndentBookmark". item	"text='".item . " texthl=" . s:id_hl.Line
	endfor
endfu

fu! <sid>UpdateView() "{{{1
	if !exists("b:changes_chg_tick")
		let b:changes_chg_tick = 0
	endif
	" Only update, if there have been changes to the buffer
	if b:changes_chg_tick != b:changedtick
		call IndentSigns#Run()
	endif
endfu

fu! IndentSigns#Run(...) "{{{1
	try
		if exists("a:1") && a:1 == 1
			unlet! s:precheck
		endif
		call <sid>Init()
		catch /^IndentSigns:/
			call <sid>WarningMsg()
		return
	endtry
	call <sid>PlaceSigns()
endfu

fu! <sid>CleanUp()"{{{1
	" only delete signs, that have been set by this plugin
	unlet! s:precheck
	call <sid>UnPlaceSigns()
	for item in range(1,10)
		exe "sil! sign undefine " item
	endfor
	" Remove IndentWSError Sign
	silent! sign undefine IndentWSError
	" Remove Custom Signs
	silent! sign undefine IndentCustom
	call <sid>AuCmd(0)
endfu

" Define Commands "{{{1
:com! IndentSigns :call IndentSigns#Run()
:com! UpdateSigns :call IndentSigns#Run(1)
:com! DisableIndentSigns :call <sid>CleanUp()

" Maping commands "{{{1
nnoremap <C-L> :call <sid>UpdateWindowSigns()<cr>

" Restore Vim Settings "{{{1
let &cpo= s:keepcpo
unlet s:keepcpo
" Modeline "{{{1
" vim: fdm=marker fdl=0 ts=4 sts=4 com+=l\:\" fdl=0 sw=4
