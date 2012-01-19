	" Signs.vim - Using Signs
" ---------------------------------------------------------------
" Version:	0.1
" Authors:	Christian Brabandt <cb@256bit.org>
" Last Change: Tue, 19 July 2010 21:16:28 +0200

" Script:  
" License: VIM License
" Documentation: N/A
" GetLatestVimScripts: 

" Documentation: N/A

" Init Folkore  -- not needed for autoload script

" Check preconditions
let s:i_path = fnamemodify(expand("<sfile>"), ':p:h') . '/Signs/'
fu! <sid>Check() "{{{1
	" Check for the existence of unsilent
	if exists(":unsilent")
		let s:echo_cmd='unsilent echomsg'
	else
		let s:echo_cmd='echomsg'
	endif

	if !has("signs")
		call add(s:msg, "Sign Support support not available in your Vim version.")
		call add(s:msg, "Signs plugin will not be working!")
		call <sid>WarningMsg()
		throw 'Signs:abort'
	endif

	let s:sign_prefix = 99
	let s:id_hl       = {}
	let s:id_hl.Line  = "DiffAdd"
	let s:id_hl.Error = "Error"
	let s:id_hl.Check = "User1"
	hi SignColumn guibg=black

	" Define Signs
	call <sid>DefineSigns()
	call <sid>UnPlaceSigns()
endfu

fu! <sid>WarningMsg() "{{{1
	redraw!
	if !empty(s:msg)
		let msg=["Signs.vim: " . s:msg[0]] + s:msg[1:]
		echohl WarningMsg
		for mess in msg
			exe s:echo_cmd "mess"
		endfor

		echohl Normal
		"let v:errmsg=msg[0]
	endif
	let s:msg=[]
endfu

fu! <sid>Init(...) "{{{1
	" Message queue, that will be displayed.
	let s:msg  = []
	
	" Setup configuration variables:
	let s:MixedIndentation = exists("g:Signs_MixedIndentation") ? 
				\ g:Signs_MixedIndentation : 1

	let s:IndentationLevel = exists("g:Signs_IndentationLevel") ?
					\ g:Signs_IndentationLevel : 1

	let s:BookmarkSigns	   = exists("g:Signs_Bookmarks") ? 
					\ g:Signs_Bookmarks : 1

	let s:Bookmarks = split("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", '\zs')

	let s:SignHook = exists("g:Signs_Hook") ? g:Signs_Hook : ''

	let s:SignQF   = exists("g:Signs_QFList") ? g:Signs_QFList : 0

	let s:SignDiff = exists("g:Signs_Diff") ? g:Signs_Diff : 0

	if !exists("s:gui_running") 
		let s:gui_running = has("gui_running")
	endif

	" Only check the first time this file is loaded
	" or Signs shall be cleared first or
	" GUI has started (use icons then)
	" It should not be neccessary to check every time
	if !exists("s:precheck") ||
		\ (exists("a:1") && a:1) ||
		\ s:gui_running != has("gui_running")
		call <sid>Check()
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
	call filter(b, 'matchstr(v:val, ''id=\zs''.s:sign_prefix.''\d\+'')')
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
	augroup Signs
		autocmd!
		au BufWritePost,InsertLeave * :call <sid>UpdateView()
		au GUIEnter * :call <sid>UpdateView()
		exe s:SignQF ? "au QuickFixCmdPost * :call DynamicSigns#QFSigns()" : ''
	augroup END
	else
	augroup Signs
		autocmd!
	augroup END
	augroup! Signs
	endif
endfu

fu! DynamicSigns#SignsQFList(local) "{{{1
	if !has("quickfix")
		return
	endif
	call <sid>Init()
	let qflist = []
	redir => a| exe "sil sign place" |redir end
	for sign in split(a, "\n")
		if match(sign, '^Signs for \(.*\):$') >= 0
			let fname = matchstr(sign, '^Signs for \zs.*\ze:$')
		elseif match(sign, '^\s\+line=\d\+\s') >= 0
			call add(qflist, {'filename': fname, 'lnum': 
				\ matchstr(sign, 'line=\zs\d\+\ze\s')})
		else
			continue
		endif
	endfor
	if a:local
		let func = 'setloclist'
		let args = [0, qflist]
	else
		let func = 'setqflist'
		let args = [qflist]
	endif
	call call(func, args)
	copen
endfu

fu! DynamicSigns#QFSigns() "{{{1
	if has("quickfix")
		if exists("s:no_qf_autocmd") && s:no_qf_autocmd
			" Don't run the autocommand
			return
		endif
		call <sid>Init()
		" Remove all previously placed QF Signs
		exe "sign unplace " s:sign_prefix . '0'
		for item in getqflist()
			exe "sign place" s:sign_prefix . '0' . " line=" . item.lnum .
				\ " name=SignQF buffer=" . item.bufnr
		endfor
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

fu! DynamicSigns#UpdateWindowSigns() "{{{1
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
	try
		let DiffSigns   = (s:SignDiff ? <sid>ReturnDiffSigns() : {})
	catch /DiffError/
		call <sid>WarningMsg()
		return
	endtry
	let first = !exists("a:1") ? 1 : a:1
	let last  = !exists("a:2") ? line('$') : a:2
	for line in range(first, last)
		let did_place_sign=0

		" Diff Signs "{{{3
		if !empty(DiffSigns)
			let oldSign = match(PlacedSigns, 'line='.line. '\D.*name=Sign\(Add\|Change\|Delete\)')
			" Added Lines
			for sign in sort(DiffSigns['a'])
				if sign == line
					if oldSign >= 0
						let did_place_sign = 1
						break
					else
						exe "sign place " s:sign_prefix . line . " line=" . line .
							\ " name=SignAdded buffer=" . bufnr('')
						let did_place_sign = 1
						break
					endif
				endif
			endfor
			if did_place_sign
				continue
			endif
			" Changed Lines
			for sign in sort(DiffSigns['c'])
				if sign == line
					exe "sign place " s:sign_prefix . line . " line=" . line .
						\ " name=SignChanged buffer=" . bufnr('')
					let did_place_sign = 1
					break
				endif
			endfor
			if did_place_sign
				continue
			endif
			" Deleted Lines
			for sign in sort(DiffSigns['d'])
				if sign == line
					exe "sign place " s:sign_prefix . line . " line=" . line .
						\ " name=SignDeleted buffer=" . bufnr('')
					let did_place_sign = 1
					break
				endif
			endfor
			if did_place_sign
				continue
			elseif oldSign >= 0
				" Diff Sign no longer needed, remove it
				call <sid>UnplaceSignSingle(line)
			endif
		endif

		" Custom Sign Hooks "{{{3
		if exists("s:SignHook") && !empty(s:SignHook)
			try
				let oldSign = match(PlacedSigns, 'line='.line. '\D.*name=IndentCustom')
				let expr = substitute(s:SignHook, 'v:lnum', line, 'g')
				if eval(expr)
					if oldSign >= 0
						continue
					endif
					exe "sign place " s:sign_prefix . line . " line=" . line .
						\ " name=IndentCustom buffer=" . bufnr('')
					continue
				elseif oldSign >= 0
					" Custom Sign no longer needed, remove it
					call <sid>UnplaceSignSingle(line)
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
					if oldSign >= 0
						let did_place_sign = 1
						break
					endif
					exe "sign place " s:sign_prefix . line . " line=" . line .
						\ " name=IndentBookmark". bookmarks[mark] . " buffer=" . bufnr('')
					let did_place_sign = 1
					break
				elseif mark > line
					break
				endif
			endfor
			if did_place_sign
				continue
			elseif oldSign >= 0
				" Bookmark Sign no longer needed, remove it
				call <sid>UnplaceSignSingle(line)
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
				call <sid>UnplaceSignSingle(line)
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
	let icon = 0
	if (has("gui_gtk") || has("gui_w32s")) && has("gui_running") 
		let icon = 1
	endif

	for item in range(1,9)
		exe "silent! sign undefine " item
		exe "sign define" item	"text=".item . " texthl=" . s:id_hl.Line
	endfor

	" Indentlevel > 9
	silent! sign undefine 10
	exe "sign define 10" 	"text=>".item . " texthl=" . s:id_hl.Error
				\ icon ? " icon=". s:i_path . "error.png" : ''

	" Mixed Indentation Error
	silent! sign undefine IndentWSError
	exe "sign define IndentWSError text=X texthl=" . s:id_hl.Error . 
		\ " linehl=" . s:id_hl.Error 
		\ icon ? " icon=". s:i_path . "error.png" : ''
	"exe "sign define IndentCheck text=C texthl=" . s:id_hl.Check . " linehl=" . s:id_hl.Check
	"
	" Custom Signs Hooks
	silent! sign undefine IndentCustom
	exe "sign define IndentCustom text=C texthl=" . s:id_hl.Error
		\ icon ? " icon=". s:i_path . "stop.png" : ''

	" Bookmark Signs
	if has("quickfix")
		for item in s:Bookmarks
			exe "silent! sign undefine IndentBookmark".item
			exe "sign define IndentBookmark". item	"text='".item . " texthl=" . s:id_hl.Line
		endfor
	endif

	" Make Errors (quickfix list)
	silent! sign undefine SignQF
	exe "sign define SignQF text=! texthl=" . s:id_hl.Check
		\ icon ? " icon=". s:i_path . "arrow-right.png" : ''

	" Diff Signs
	silent! sign undefine SignAdded
	silent! sign undefine SignChanged
	silent! sign undefine SignDeleted

	if has("diff")
		exe "sign define SignAdded text=+ texthl=DiffAdd"
					\ icon ? " icon=". s:i_path . "add.png" : ''
		exe "sign define SignChanged text=M texthl=DiffChange"
					\ icon ? " icon=". s:i_path . "warning.png" : ''
		exe "sign define SignDeleted text=- texthl=DiffDelete"
					\ icon ? " icon=". s:i_path . "delete.png" : ''
	endif
endfu

fu! <sid>ReturnDiffSigns() "{{{1
	if !executable("diff") ||
		\ empty(expand("%")) ||
		\ !has("diff")
		" nothing to do
		call add(s:msg, 'Diff not possible:' . 
			\ (!executable("diff") ? ' No diff executable found!' :
			\ empty(expand("%")) ? ' Current file has never been written!' :
			\ 'Vim was compiled without diff feature!'))
		throw "DiffError"
	endif
	let new_file = tempname()
	let cmd = "diff "
	if &dip =~ 'icase'
		let cmd .= "-i "
	endif
	if &dip =~ 'iwhite'
		let cmd .= "-b "
	endif
	let cmd .=  shellescape(expand("%")) . " " .
				\ shellescape(new_file, 1)
	call writefile(getline(1,'$'), new_file)
	let result = split(system(cmd), "\n")

	if v:shell_error == -1 || (v:shell_error && v:shell_error != 1)
		call add(s:msg, "There was an error executing the diff command!")
		call add(s:msg, result[0])
		throw "DiffError"
	endif
	call filter(result, 'v:val =~ ''^\d\+\(,\d\+\)\?[acd]\d\+\(,\d\+\)\?''')
	" Init result set
	let diffsigns = {}
	let diffsigns['a'] = []
	let diffsigns['c'] = []
	let diffsigns['d'] = []
	" parse diff output
	for item in result
		let m = matchlist(item, '^\v%(\d+)%(,%(\d+))?([acd])(\d+)%(,?(\d+)?)')
		if empty(m)
			continue
		endif
		if m[2] == 0
			let m[2] = 1
		endif

		"call add(diffsigns[m[3]], range(m[1], empty(m[2]) ? m[1] : m[2]))
		let diffsigns[m[1]] = diffsigns[m[1]] + range(m[2], empty(m[3]) ? m[2] : m[3])
	endfor
	return diffsigns
endfu



fu! <sid>UpdateView() "{{{1
	if !exists("b:changes_chg_tick")
		let b:changes_chg_tick = 0
	endif
	" Only update, if there have been changes to the buffer
	if b:changes_chg_tick != b:changedtick
		call DynamicSigns#Run()
	endif
endfu

fu! DynamicSigns#Run(...) "{{{1
	try
		if exists("a:1") && a:1 == 1
			unlet! s:precheck
		endif
		call <sid>Init()
		catch /^Signs:/
			call <sid>WarningMsg()
		return
	endtry
	call <sid>PlaceSigns()
endfu

fu! DynamicSigns#CleanUp()"{{{1
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



" Modeline "{{{1
" vim: fdm=marker fdl=0 ts=4 sts=4 com+=l\:\" fdl=0 sw=4