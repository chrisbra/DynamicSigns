" DynamicSigns.vim - Using Signs for different things
" ---------------------------------------------------------------
"Author:		Christian Brabandt <cb@256bit.org>
"License:		VIM License (see :h license)
"URL:			http://www.github.com/chrisbra/DynamicSigns
"Documentation:	DynamicSigns.txt
"Version:		0.2
"Last Change: Thu, 15 Mar 2012 23:37:37 +0100
"GetLatestVimScripts:  XXX 2 :AutoInstall: DynamicSigns.vim

" Check preconditions
scriptencoding utf-8
let s:plugin = fnamemodify(expand("<sfile>"), ':t:r')
let s:i_path = fnamemodify(expand("<sfile>"), ':p:h'). '/'. s:plugin. '/'

fu! <sid>Check() "{{{1
	" Check for the existence of unsilent
	if exists(":unsilent")
		let s:echo_cmd='unsilent echomsg'
	else
		let s:echo_cmd='echomsg'
	endif

	if !has("signs")
		call add(s:msg, "Sign Support support not available" . 
				\ "in your Vim version.")
		call add(s:msg, "Signs plugin will not be working!")
		call <sid>WarningMsg()
		throw 'Signs:abort'
	endif

	let s:sign_prefix = 99
	let s:id_hl       = {}
	let s:id_hl.Line  = "DiffAdd"
	let s:id_hl.Error = "Error"
	let s:id_hl.Check = "User1"
	let s:id_hl.LineEven = exists("g:DynamicSigns_Even") ? g:DynamicSigns_Even	: 
				\ <sid>Color("Even")

	let s:id_hl.LineOdd  = exists("g:DynamicSigns_Odd")  ? g:DynamicSigns_Odd	:
				\ <sid>Color("Odd")
	
	hi SignColumn guibg=black

	call <sid>UnPlaceSigns()
	" Undefine Signs
	call DynamicSigns#CleanUp()
	" Define Signs
	call <sid>DefineSigns()
endfu

fu! <sid>Color(name) "{{{1
	let definition = ''
	if a:name == 'Even'
		if &bg == 'dark'
			if !empty(&t_Co) && &t_Co < 88
				let definition .= ' ctermbg=DarkGray'
			else
				let definition .= ' ctermbg='. (&t_Co == 88 ? '80' : '234') .
					\ ' guibg=#292929'
			endif
		else
			if !empty(&t_Co) && &t_Co < 88
				let definition .= ' ctermbg=LightGrey'
			else
				let definition .= ' ctermbg='. (&t_Co == 88 ? '86' : '245') .
					\ ' guibg=#525252'
			endif
		endif
		exe "hi LineEven" definition
		return 'LineEven'
	else
		if &bg == 'dark'
			if !empty(&t_Co) && &t_Co < 88
				let definition .= ' ctermbg=LightGray'
			else
				let definition .= ' ctermbg='. (&t_Co == 88 ? '86' : '245') .
					\ ' guibg=#525252'
			endif
		else
			if !empty(&t_Co) && &t_Co < 88
				let definition .= ' ctermbg=LightGrey'
			else
				let definition .= ' ctermbg='. (&t_Co == 88 ? '80' : '234') .
					\ ' guibg=#292929'
			endif
		endif
		exe "hi LineOdd" definition
		return 'LineOdd'
	endif
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
		let s:msg=[]
	endif
endfu

fu! <sid>Init(...) "{{{1
	" Message queue, that will be displayed.
	let s:msg  = []
	
	" Setup configuration variables:
	let s:MixedIndentation = exists("g:Signs_MixedIndentation") ? 
				\ g:Signs_MixedIndentation : 0

	let s:IndentationLevel = exists("g:Signs_IndentationLevel") ?
				\ g:Signs_IndentationLevel : 0

	let s:BookmarkSigns   = exists("g:Signs_Bookmarks") ? 
				\ g:Signs_Bookmarks : 0

	let s:AlternatingSigns = exists("g:Signs_Alternate") ?
				\ g:Signs_Alternate : 0

	let s:Bookmarks = split("abcdefghijklmnopqrstuvwxyz" .
				\ "ABCDEFGHIJKLMNOPQRSTUVWXYZ", '\zs')

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

	" Cache Configuration
	if !exists("s:CacheOpts")
		let s:CacheOpts = {}
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
	call <sid>RemoveDeletedSigns(filter(copy(b),
		\ 'matchstr(v:val, ''deleted'')'))
	call filter(b, 'matchstr(v:val, ''id=\zs''.s:sign_prefix.''\d\+'')')
	return b
endfu

fu! <sid>RemoveDeletedSigns(list) "{{{1
	for sign in a:list
		let id=matchstr(sign, 'id=\zs\d\+')
		exe "sil sign unplace" id "buffer=". bufnr('')
	endfor
endfu


fu! <sid>AuCmd(arg) "{{{1
	if a:arg
		augroup Signs
			autocmd!
			au InsertLeave * :call <sid>UpdateView(0)
			au GUIEnter,BufWritePost * :call <sid>UpdateView(1)
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
			let file  = readfile(fname)
		elseif match(sign, '^\s\+line=\d\+\s') >= 0
			let line = matchstr(sign, 'line=\zs\d\+\ze\s')
			call add(qflist, {'filename': fname, 'lnum': line,
				\ 'text': file[line-1]})
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
	let s:no_qf_autocmd = 1
	call call(func, args)
	unlet s:no_qf_autocmd 
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
	call cursor(a:item,0)
	" Vim errors, if the line does not contain a sign
	sil! sign unplace
endfu

fu! <sid>UnplaceSignID(id) "{{{1
	exe "sil sign unplace ". a:id. " buffer=".bufnr('')
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

fu! <sid>SkipFoldedLines(lineend, range) "{{{1
	let range = a:range
	if a:lineend == -1
		return
	endif
	call filter(range, 'v:val >= a:lineend')
endfu

fu! <sid>PlaceSigns(...) "{{{1
	try
		let DiffSigns   = (s:SignDiff ? <sid>ReturnDiffSigns() : {})
	catch /DiffError/
		call <sid>WarningMsg()
		return
	endtry
	if !<sid>DoSigns()
		return
	endif
	let first = !exists("a:1") ? 1 : a:1
	let last  = !exists("a:2") ? line('$') : a:2
	let range = range(first, last)
	for line in range
		let did_place_sign = 0
		" Place alternating Signs "{{{3
		" don't skip folded lines
		if <sid>PlaceAlternatingSigns(line)
			continue
		endif

		" Skip folded lines
		if foldclosed(line) != -1
			call <sid>SkipFoldedLines(foldclosedend(line), range)
			continue
		endif

		" Place Diff Signs "{{{3
		if <sid>PlaceDiffSigns(line, DiffSigns)
			continue
		endif

		" Place marks "{{{3
		if <sid>PlaceBookmarks(line)
			continue
		endif

		" Custom Sign Hooks "{{{3
		let i = <sid>PlaceSignHook(line)
		if i > 0
			continue
		elseif i < 0
			" Evaluating expression failed, don't avoid generating more errors
			" for the rest of the lines
			return
		endif

		" Place signs for mixed indentation rules "{{{3
		if <sid>PlaceMixedWhitespaceSign(line)
			continue
		endif

		" Place signs for Indentation Level {{{3
		if <sid>PlaceIndentationSign(line)
			continue
		endif

	endfor
	" Cache for configuration options
	call <sid>BufferConfigCache()
endfu

fu! <sid>DefineSignsIcons(def) "{{{1
	try
		exe a:def
	catch /^Vim\%((\a\+)\)\=:E255/
		" gvim can't read the icon
		exe substitute(a:def, 'icon=.*$', '', '')
	endtry
endfu

fu! <sid>DefineSigns() "{{{1
	let icon = 0
	if (has("gui_gtk") || has("gui_win32") || has("win32") || has("win64"))
		\ && has("gui_running") 
		let icon = 1
	endif

	for item in range(1,9)
		exe "sign define" item	"text=".item . " texthl=" . s:id_hl.Line
	endfor

	" Indentlevel > 9
	let def = printf("sign define 10 text=>9 texthl=%s %s",
				\ s:id_hl.Error, (icon ? "icon=". s:i_path. "error.bmp" : ''))
	call <sid>DefineSignsIcons(def)

	" Mixed Indentation Error
	let utf8signs = (&enc=='utf-8' || (exists("g:NoUtf8Signs") &&
		\ !g:NoUtf8Signs) ? 1 : 0)
	let def = printf("sign define SignWSError text=X texthl=%s linehl=%s %s",
				\ s:id_hl.Error, s:id_hl.Error,
				\ (icon ? "icon=". s:i_path. "error.bmp" : ''))
	call <sid>DefineSignsIcons(def)
	"
	" Custom Signs Hooks
	for sign in ['OK', 'Warning', 'Error', 'Info', 'Add', 'Arrow', 'Flag',
		\ 'Delete', 'Stop']
		let icn  = (icon ? 'icon='. s:i_path : '')
		let text = ""
		if sign ==     'OK'
			let text = (utf8signs ? '✓' : 'OK')
			let icn  = (empty(icn) ? '' : icn . 'checkmark.bmp')
		elseif sign == 'Warning'
			let text = (utf8signs ? '⚠' : '!')
			let icn  = (empty(icn) ? '' : icn . 'warning.bmp')
		elseif sign == 'Error'
			let text = 'X'
			let icn  = (empty(icn) ? '' : icn . 'error.bmp')
		elseif sign == 'Info'
			let text = (utf8signs ? 'ℹ' : 'I')
			let icn  = (empty(icn) ? '' : icn . 'thumbtack-yellow.bmp')
		elseif sign == 'Add'
			let text = '+'
			let icn  = (empty(icn) ? '' : icn . 'add.bmp')
		elseif sign == 'Arrow'
			let text = (utf8signs ? '→' : '->')
			let icn  = (empty(icn) ? '' : icn . 'arrow-right.bmp')
		elseif sign == 'Flag'
			let text = (utf8signs ? '⚑' : 'F')
			let icn  = (empty(icn) ? '' : icn . 'flag-yellow.bmp')
		elseif sign == 'Delete'
			let text = (utf8signs ? '‒' : '-')
			let icn  = (empty(icn) ? '' : icn . 'delete.bmp')
		elseif sign == 'Stop'
			let text = 'ST'
			let icn  = (empty(icn) ? '' : icn . 'stop.bmp')
		endif

		let def = printf("sign define SignCustom%s text=%s texthl=%s " .
			\ "%s", sign, text, s:id_hl.Error, icn)
		call <sid>DefineSignsIcons(def)
	endfor

	" Bookmark Signs
	if has("quickfix")
		for item in s:Bookmarks
			exe "sign define SignBookmark". item	"text='".item .
				\ " texthl=" . s:id_hl.Line
		endfor
	endif

	" Make Errors (quickfix list)
	let def = printf("sign define SignQF text=! texthl=%s %s",
			\ s:id_hl.Check, (icon ? " icon=". s:i_path. "arrow-right.bmp" : ''))
	call <sid>DefineSignsIcons(def)

	" Diff Signs
	if has("diff")
		let def = printf("sign define SignAdded text=+ texthl=DiffAdd %s",
					\ (icon ? " icon=". s:i_path . "add.bmp" : ''))
		call <sid>DefineSignsIcons(def)
		let def = printf("sign define SignChanged text=M texthl=DiffChange %s",
					\ (icon ? " icon=". s:i_path . "warning.bmp" : ''))
		call <sid>DefineSignsIcons(def)
		let def = printf("sign define SignDeleted text=- texthl=DiffDelete %s",
					\ (icon ? " icon=". s:i_path . "delete.bmp" : ''))
		call <sid>DefineSignsIcons(def)
	endif

	" Alternating Colors
	exe "sign define SignEven linehl=". s:id_hl.LineEven
	exe "sign define SignOdd linehl=".  s:id_hl.LineOdd
endfu

fu! <sid>ReturnDiffSigns() "{{{1
	let fname = expand('%')
	if !executable("diff")	||
		\ empty(fname)		||
		\ !has("diff")		||
		\ !filereadable(fname) 
		" nothing to do
		call add(s:msg, 'Diff not possible:' . 
			\ (!executable("diff") ? ' No diff executable found!' :
			\ empty(fname) ? ' Current file has never been written!' :
			\ !filereadable(fname) ? ' '. fname. ' not readable!' :
			\ ' Vim was compiled without diff feature!'))
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

fu! <sid>UpdateView(force) "{{{1
	if !exists("b:changes_chg_tick")
		let b:changes_chg_tick = 0
	endif
	" Only update, if there have been changes to the buffer
	if b:changes_chg_tick != b:changedtick || a:force
		call DynamicSigns#Run()
		let b:changes_chg_tick = b:changedtick
	endif
endfu

fu! DynamicSigns#Run(...) "{{{1
	set lz
	let _a = winsaveview()
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
	set nolz
	call winrestview(_a)
endfu

fu! DynamicSigns#CleanUp() "{{{1
	" only delete signs, that have been set by this plugin
	call <sid>UnPlaceSigns()
	for item in range(1,10)
		exe "sil! sign undefine " item
	endfor
	" Remove SignWSError Sign
	sil! sign undefine SignWSError
	" Remove Custom Signs
	for sign in ['OK', 'Warning', 'Error', 'Info', 'Add', 'Arrow', 'Flag',
		\ 'Delete', 'Stop']
		exe "sil! sign undefine SignCustom". sign
	endfor
	for sign in s:Bookmarks
		exe "sil! sign undefine SignBookmark".sign
	endfor
	for sign in ['SignQF', 'SignAdded', 'SignChanged', 'SignDeleted']
		exe "sil! sign undefine" sign
	endfor
	call <sid>AuCmd(0)
	unlet! s:precheck
endfu

fu! DynamicSigns#PrepareSignExpression(arg) "{{{1
	let g:Signs_Hook = a:arg
	call DynamicSigns#Run()
endfu

fu! <sid>MySortBookmarks(a, b) "{{{¹
	return a:a+0 == a:b+0 ? 0 : a:a+0 > a:b+0 ? 1: -1
endfu


fu! <sid>DoSigns() "{{{1
	if !s:MixedIndentation &&
		\ get(s:CacheOpts, 'MixedIndentation', 0) > 0
		let index = match(s:Signs,
			\ 'id='.s:sign_prefix.'\d\+.*name=SignWSError')
		while index > -1
			let line = matchstr(s:Signs[index], 'line=\zs\d\+\ze\D')
			call <sid>UnplaceSignID(s:sign_prefix.line)
			call remove(s:Signs, index)
			let index = match(s:Signs, 'id='.s:sign_prefix.
				\ '\d\+.*name=SignWSError') 
		endw

	elseif !s:IndentationLevel &&
		\ get(s:CacheOpts, 'IndentationLevel', 0) > 0
		let index = match(s:Signs, 'id='.s:sign_prefix.'\d\+.*name=\d\+')
		while index > -1
			let line = matchstr(s:Signs[index], 'line=\zs\d\+\ze\D')
			call <sid>UnplaceSignID(s:sign_prefix.line)
			call remove(s:Signs, index)
			let index = match(s:Signs, 'id='.s:sign_prefix.'\d\+.*name=\d\+') 
		endw

	elseif !s:SignHook &&
		\ get(s:CacheOpts, 'SignHook', 0) > 0
		let index = match(s:Signs, 'id='.s:sign_prefix.'\d\+.*name=SignCustom')
		while index > -1
			let line = matchstr(s:Signs[index], 'line=\zs\d\+\ze\D')
			call <sid>UnplaceSignID(s:sign_prefix.line)
			call remove(s:Signs, index)
			let index = match(s:Signs, 'id='.s:sign_prefix.
				\ '\d\+.*name=SignCustom') 
		endw

	elseif !s:SignDiff &&
		\ get(s:CacheOpts, 'SignDiff', 0) > 0
		let index = match(s:Signs, 'id='.s:sign_prefix.
			\ '\d\+.*name=Sign\(Add\|Change\|Delete\)')
		while index > -1
			let line = matchstr(s:Signs[index], 'line=\zs\d\+\ze\D')
			call <sid>UnplaceSignID(s:sign_prefix.line)
			call remove(s:Signs, index)
			let index = match(s:Signs, 'id='.s:sign_prefix.
				\ '\d\+.*name=Sign\(Add\|Change\|Delete\)')
		endw
	endif
	call <sid>DoSignBookmarks()

	if (  !s:MixedIndentation  &&
		\ !s:IndentationLevel  &&
		\ !s:BookmarkSigns	   &&
		\ !s:SignHook		   &&
		\ !s:SignDiff )
		unlet! s:CacheOpts
		return 0
	else
		return 1
	endif
endfu

fu! <sid>DoSignBookmarks() "{{{1
	if s:BookmarkSigns != get(s:CacheOpts, 'BookmarkSigns', 0)
		let index = match(s:Signs,
			\'id='.s:sign_prefix.'\d\+.*name=SignBookmark')
		while index > -1
			let line = matchstr(s:Signs[index], 'line=\zs\d\+\ze\D')
			call <sid>UnplaceSignID(s:sign_prefix.line)
			call remove(s:Signs, index)
			let index = match(s:Signs, 'id='.s:sign_prefix.
				\ '\d\+.*name=SignBookmark') 
		endw
	endif
	return s:BookmarkSigns
endfu

fu! <sid>BufferConfigCache() "{{{1
	if !exists("s:CacheOpts")
		let s:CacheOpts = {}
	endif
	let s:CacheOpts.MixedIndentation = s:MixedIndentation
	let s:CacheOpts.IndentationLevel = s:IndentationLevel
	let s:CacheOpts.BookmarkSigns    = s:BookmarkSigns
	let s:CacheOpts.SignHook		 = s:SignHook
	let s:CacheOpts.SignDiff		 = s:SignDiff
endfu

fu! <sid>PlaceIndentationSign(line) "{{{1
	if exists("s:IndentationLevel") &&
				\ s:IndentationLevel == 1
		let indent = indent(a:line)
		let div    = <sid>IndentFactor()

		let oldSign = match(s:Signs, 'line='.a:line.
			\ '.*name=SignWSError')
		if div > 0 && indent > 0 
			if oldSign < 0
				exe "sign place " s:sign_prefix . a:line . " line=" . a:line .
					\ " name=" . (indent/div < 10 ? indent/div : '10').
					\ " buffer=" . bufnr('')
			endif
			return 1
		elseif oldSign >= 0
			"no more indentation Signs needed, remove
			call <sid>UnplaceSignSingle(a:line)
		endif
	endif 
	return 0
endfu

fu! <sid>PlaceMixedWhitespaceSign(line) "{{{1
	if exists("s:MixedIndentation") &&
				\ s:MixedIndentation == 1

		let a=matchstr(getline(a:line), '^\s\+\ze\S')
		let oldSign = match(s:Signs, 'line='.a:line.
					\ '.*name=SignWSError')
		if (match(a, '\%(\t \)\|\%( \t\)') > -1
			\ || match(getline(a:line), '\s\+$') > -1)

			if oldSign < 0
				exe "sign place " s:sign_prefix. a:line. " line=". a:line.
					\ " name=SignWSError buffer=" . bufnr('')
			endif
			return 1
		elseif oldSign >= 0
			" No more wrong indentation, remove sign
			call <sid>UnplaceSignSingle(a:line)
		endif
	endif
	return 0
endfu
fu! <sid>PlaceSignHook(line) "{{{1
	if exists("s:SignHook") && !empty(s:SignHook)
		try
			let expr = substitute(s:SignHook, 'v:lnum', a:line, 'g')
			let a = eval(expr)
			let result = matchstr(a,
				\'Warning\|OK\|Error\|Info\|Add\|Arrow\|Flag\|'.
				\ 'Delete\|Stop')
			if empty(result)
				let result = 'Info'
			endif
			let oldSign = match(s:Signs, 'line='. a:line.
					\ '\D.*name=SignCustom'.result)
			if a
				if oldSign == -1
					exe "sign place " s:sign_prefix. a:line. " line=". a:line.
						\ " name=SignCustom". result. " buffer=". bufnr('')
				endif
				return 1
			elseif oldSign >= 0
				" Custom Sign no longer needed, remove it
				call <sid>UnplaceSignSingle(a:line)
			endif
			return 0
		catch
			let s:SignHook = ''
			call add(s:msg, 'Error evaluating SignExpression at '. line)
			call add(s:msg, v:exception)
			call <sid>WarningMsg()
			return -1
		endtry
	endif
endfu
fu! <sid>PlaceDiffSigns(line, DiffSigns) "{{{1
	" Diff Signs
	let did_place_sign = 0
	if !empty(a:DiffSigns)
		let oldSign = match(s:Signs, 'line='.a:line. '\D.*name=SignAdd')

		" Added Lines
		for sign in sort(a:DiffSigns['a'])
			if sign == a:line
				if oldSign < 0
					exe "sign place " s:sign_prefix. a:line. " line=".
						\ a:line. " name=SignAdded buffer=". bufnr('')
				endif
				let did_place_sign = 1
				break
			endif
		endfor
		if did_place_sign
			continue
		endif

		" Changed Lines
		let oldSign = match(s:Signs, 'line='. a:line. 
				\ '\D.*name=SignChange')
		for sign in sort(a:DiffSigns['c'])
			if sign == a:line
				if oldSign < 0
					exe "sign place " s:sign_prefix. a:line. " line=".
						\ a:line. " name=SignChanged buffer=". bufnr('')
				endif
				let did_place_sign = 1
				break
			endif
		endfor
		if did_place_sign
			continue
		endif

		" Deleted Lines
		let oldSign = match(s:Signs, 'line='. a:line.
				\ '\D.*name=SignDelete')
		for sign in sort(a:DiffSigns['d'])
			if sign == a:line
				if oldSign < 0
					exe "sign place " s:sign_prefix. a:line. " line=".
						\ a:line. " name=SignDeleted buffer=". bufnr('')
				endif
				let did_place_sign = 1
				break
			endif
		endfor

		if did_place_sign
			return 1
		elseif oldSign >= 0
			" Diff Sign no longer needed, remove it
			call <sid>UnplaceSignSingle(a:line)
		endif
	endif
	return 0
endfu

fu! <sid>PlaceAlternatingSigns(line) "{{{1
	if !s:AlternatingSigns
		return 0
	endif
	let oldSign = match(s:Signs, 'line='. a:line. '\s*id='. s:sign_prefix
			\ . a:line. '\s*name=Sign'. (a:line % 2 ? 'Odd': 'Even'))
	let oldSign1 = match(s:Signs, 'line='. a:line. '\s*id='. s:sign_prefix
			\ . a:line. '\s*name=Sign')
	if oldSign == -1
		if oldSign1 > -1
			" unplace previously place sign first
			call <sid>UnplaceSignSingle(a:line)
		endif
		let sign = printf('sign place %d%d line=%d name=%s buffer=%d',
					\ s:sign_prefix, a:line, a:line,
					\ (a:line % 2 ? "SignOdd" : "SignEven"), bufnr(''))
		exe sign
	endif
	return 1
endfu

fu! <sid>PlaceBookmarks(line) "{{{1
	" Place signs for bookmarks
	if exists("s:BookmarkSigns") &&
				\ s:BookmarkSigns == 1
		let oldSign = match(s:Signs, 'line='. a:line.
				\ '\D.*name=SignBookmark')
		
		let bookmarks   = <sid>GetMarks()
		if get(bookmarks, a:line, -1) > -1
			if oldSign < 0
				exe "sign place " s:sign_prefix. a:line. " line=". a:line.
					\ " name=SignBookmark". bookmarks[a:line]. " buffer=".
					\ bufnr('')
			endif
			return 1
		elseif oldSign >= 0
			" Bookmark Sign no longer needed, remove it
			call <sid>UnplaceSignSingle(a:line)
		endif
	endif
	return 0
endfu

fu! DynamicSigns#MapBookmark() "{{{1
	let a = getchar()
	if type(a) == type(0)
		let char = nr2char(a)
	else
		let char = a
	endif
	" Initilize variables
	call <sid>Init()
	if <sid>DoSignBookmarks()
		" unplace previous mark for this sign
		" not necessary, has already been dony by DoSignBookmarks
		let line = line('.')
		let sign_cmd =
			\ printf(":sign place %d%d line=%d name=SignBookmark%s buffer=%d",
			\ s:sign_prefix, line, line, char, bufnr(''))
		exe sign_cmd
		" Also place all signs, that are on the current buffer
		" Only place them in the current window, this is faster than having to
		" iterate over the whole buffer
	    for line in range(line('w0'), line('w$'))
			" No signs are placed for folded lines
			if foldclosed(line) != -1
				continue
			endif
			call <sid>PlaceBookmarks(line)
		endfor
	endif
	call <sid>BufferConfigCache()
	return 'm'.char
endfu

fu! DynamicSigns#MapKey()
	" Does not work: Error
	" E15: Invalid expression: <80><fd>SDynamicSignsMapBookmark
	" This looks like a bug in vim
	" nnoremap <silent> <expr> <Plug>DynamicSignsMapBookmark DynamicSigns#MapBookmark()
	if !hasmapto('DynamicSigns#MapBookmark', 'n')
		nnoremap <expr> m DynamicSigns#MapBookmark()
	endif
endfu
" Modeline "{{{1
" vim: fdm=marker fdl=0 ts=4 sts=4 com+=l\:\" fdl=0 sw=4
