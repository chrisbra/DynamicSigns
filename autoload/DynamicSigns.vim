" DynamicSigns.vim - Using Signs for different things
" ---------------------------------------------------------------
"Author:		Christian Brabandt <cb@256bit.org>
"License:		VIM License (see :h license)
"URL:			http://www.github.com/chrisbra/DynamicSigns
"Documentation:	DynamicSigns.txt
"Version:		0.1
"Last Change: Thu, 15 Mar 2012 23:37:37 +0100
"GetLatestVimScripts:  3965 1 :AutoInstall: DynamicSigns.vim

fu! <sid>GetSID()
	return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_GetSID$')
endfu

" Check preconditions
scriptencoding utf-8
let s:plugin = fnamemodify(expand("<sfile>"), ':t:r')
let s:i_path = fnamemodify(expand("<sfile>"), ':p:h'). '/'. s:plugin. '/'


let s:sid    = <sid>GetSID()
delf <sid>GetSID "not needed anymore

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

	let s:sign_prefix = s:sid
	let s:id_hl       = {}
	let s:id_hl.Line  = "DiffAdd"
	let s:id_hl.Error = "Error"
	let s:id_hl.Check = "User1"
	let s:id_hl.LineEven = exists("g:DynamicSigns_Even") ? g:DynamicSigns_Even	: 
				\ <sid>Color("Even")

	let s:id_hl.LineOdd  = exists("g:DynamicSigns_Odd")  ? g:DynamicSigns_Odd	:
				\ <sid>Color("Odd")
	
	hi SignColumn guibg=black

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

	" Don't draw an ascii scrollbar in the gui, because it does not look nice
	" and the gui can display its own scrollbar
	let s:SignScrollbar = exists("g:Signs_Scrollbar") ?
				\ (g:Signs_Scrollbar && !has("gui_running")) : 0
	
	let s:Sign_CursorHold = exists("g:Signs_CursorHold") ? g:Signs_CursorHold : 0

	let s:debug    = exists("g:Signs_Debug") ? g:Signs_Debug : 0

	let s:ignore   = exists("g:Signs_Ignore") ?
				   \ split(g:Signs_Ignore, ',')  : []

	if !exists("s:gui_running") 
		let s:gui_running = has("gui_running")
	endif

	" Highlighting for the bookmarks
	if !exists("s:BookmarkSignsHL")
		let s:BookmarkSignsHL = {}
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

	" Need to redefine existing Signs?
	if exists("g:NoUtf8Signs") &&
	 \ g:NoUtf8Signs != get(s:CacheOpts, 'NoUtf8Signs', -1)
		call DynamicSigns#CleanUp()
		call <sid>DefineSigns()
	endif

	" Create CursorMoved autocommands
	if s:SignScrollbar
		call <sid>DoSignScrollbarAucmd(1)
	endif

	" This is needed, to not mess with signs placed by the user
	let s:Signs = <sid>ReturnSigns(bufnr(''))
	call <sid>AuCmd(1)
endfu

fu! <sid>IndentFactor() "{{{1
	return &l:sts>0 ? &l:sts : &ts
endfu

fu! <sid>ReturnSignDef() "{{{1
	redir => a
		sil sign list
	redir END
	let b = split(a, "\n")[2:]
	call map(b, 'split(v:val)[1]')
	return filter(b, 'v:val=~''^\(Sign\)\|\(\d\+$\)''')
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
	" Don't update signs for 
	" marks on insertleave
	if a:arg
		augroup Signs
			autocmd!
			au InsertLeave * :call DynamicSigns#UpdateWindowSigns('marks')
			au GUIEnter,BufWinEnter,VimEnter *
				\ call DynamicSigns#UpdateWindowSigns('')
			au BufWritePost *
				\ call DynamicSigns#UpdateWindowSigns('marks')
			exe s:SignQF ?
				\ "au QuickFixCmdPost * :call DynamicSigns#QFSigns()" : ''
			if exists("s:Sign_CursorHold") && s:Sign_CursorHold
				au CursorHold,CursorHoldI * 
					\ call DynamicSigns#UpdateWindowSigns('marks')
			endif
		augroup END
	else
		augroup Signs
			autocmd!
		augroup END
		augroup! Signs
	endif
endfu

fu! <sid>DoSignScrollbarAucmd(arg) "{{{1
	if a:arg
		augroup SignsScrollbar
			autocmd!
			au CursorMoved,CursorMovedI,VimResized,BufEnter * 
				\ :call DynamicSigns#UpdateScrollbarSigns()
		augroup END
	else
		augroup SignsScrollbar
			autocmd!
		augroup END
		augroup! SignsScrollbar
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
	let c=filter(copy(b), 'v:val !~ "id=". s:sign_prefix || v:val =~ ''Deleted'' ')
	if empty(c)
		" Can unplace all signs
		if v:version > 703 || (v:version = 703 && has("patch596"))
			exe "sign unplace * bufnr=". bufnr('%')
		else
			for id in b
				exe "sign unplace" id
			endfor
		endif
	else
		let b=filter(b, 'v:val =~ "id=".s:sign_prefix')
		let b=map(b, 'matchstr(v:val, ''id=\zs\d\+'')')
		for id in b
			exe "sign unplace" id
		endfor
	endif
endfu

fu! <sid>UnMatchHL() "{{{1
	if exists("s:BookmarkSignsHL")
		for value in values(s:BookmarkSignsHL)
			sil! call matchdelete(value)
		endfor
	endif

	if exists("s:MixedIndentationHL")
		sil! call matchdelete(s:MixedIndentationHL
	endif
	let s:BookmarkSignsHL = {}
endfu

fu! <sid>DoBookmarkHL() "{{{1
	if exists("s:BookmarkSigns")
		\ && s:BookmarkSigns == 1
		let PlacedSigns = copy(s:Signs)
		let pat = 'id='.s:sign_prefix.'\d\+[^0-9=]*=SignBookmark\(.\)'
		let Sign = matchlist(PlacedSigns, pat)
		if !exists("s:BookmarkSignsHL")
			let s:BookmarkSignsHL = {}
		endif
		while (!empty(Sign))
			let s:BookmarkSignsHL[Sign[1]] = matchadd('WildMenu',
						\ <sid>GetPattern(Sign[1]))
			call remove(PlacedSigns, match(PlacedSigns, pat))
			let Sign = matchlist(PlacedSigns, pat)
		endw
	endif
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

fu! <sid>GetMarks() "{{{1
	let marks={}
	let t = []
	for mark in s:Bookmarks
		let t = getpos("'".mark)
		if t[1] > 0 && (t[0] == bufnr("%") || t[0] == 0)
			let marks[mark] = t[1]
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
	let s:bookmarks =  {}
	if s:BookmarkSigns
		let s:bookmarks = <sid>GetMarks()
	endif
	let first = !exists("a:1") ? 1 : a:1
	let last  = !exists("a:2") ? line('$') : a:2
	let range = range(first, last)
	for line in range
		let did_place_sign = 0
		" Place alternating Signs "{{{3
		" don't skip folded lines
		if match(s:ignore, 'alternate') == -1 &&
			\ <sid>PlaceAlternatingSigns(line)
			continue
		endif

		" Skip folded lines
		if foldclosed(line) != -1 "{{{3
			call <sid>SkipFoldedLines(foldclosedend(line), range)
			continue
		endif

		" Place Diff Signs "{{{3
		if match(s:ignore, 'diff') == -1 && 
			\ <sid>PlaceDiffSigns(line, DiffSigns)
			continue
		endif

		" Place Bookmarks "{{{3
		if match(s:ignore, 'marks') == -1 && 
			\ <sid>PlaceBookmarks(line)
			continue
		endif

		" Custom Sign Hooks "{{{3
		if match(s:ignore, 'expression') == -1
			let i = <sid>PlaceSignHook(line)
			if i > 0
				continue
			elseif i < 0
				" Evaluating expression failed, don't avoid
				" generating more errors for the rest of the lines
				return
			endif
		endif

		" Place signs for mixed indentation rules "{{{3
		if match(s:ignore, 'whitespace') == -1  &&
			\ <sid>PlaceMixedWhitespaceSign(line)
			continue
		endif

		" Place signs for Indentation Level {{{3
		if match(s:ignore, 'indentation') == -1 &&
			\ <sid>PlaceIndentationSign(line)
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
		" first undefine the sign
		exe "sign undefine" matchstr(a:def, '^sign define \zs\S\+\ze')
		" redefine the sign without an icon
		exe substitute(a:def, 'icon=.*$', '', '')
	endtry
endfu

fu! <sid>DefineSigns() "{{{1
	let icon = 0
	if (has("gui_gtk") || has("gui_win32") || has("win32") || has("win64"))
		\ && has("gui_running") 
		let icon = 1
	endif

	let utf8signs = (exists("g:NoUtf8Signs") ? !g:NoUtf8Signs : 1)

	if utf8signs && &enc != 'utf-8'
		let utf8signs = 0
	endif

	for item in range(1,9)
		let def = printf("sign define %d text=%d texthl=%s %s",
			\	item, item, s:id_hl.Line, (icon ? 'icon='.s:i_path.item.'.bmp' : ''))
		call <sid>DefineSignsIcons(def)
	endfor

	" Indentlevel > 9
	let def = printf("sign define 10 text=>9 texthl=%s %s",
				\ s:id_hl.Error, (icon ? "icon=". s:i_path. "error.bmp" : ''))
	call <sid>DefineSignsIcons(def)
	
	" Indentlevel < 1
	let def = printf("sign define 0 text=<1 texthl=%s %s",
				\ s:id_hl.Error, (icon ? "icon=". s:i_path. "warning.bmp" : ''))
	call <sid>DefineSignsIcons(def)

	" Mixed Indentation Error
	let def = printf("sign define SignWSError text=X texthl=%s %s",
				\ s:id_hl.Error, 
				\ (icon ? "icon=". s:i_path. "error.bmp" : ''))
	call <sid>DefineSignsIcons(def)
	
	" Scrollbar
	exe printf("sign define SignScrollbar text=%s texthl=%s",
				\ (utf8signs ? '██': '>>'), s:id_hl.Check)
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
	for item in s:Bookmarks
		let icn = ''
		if item =~# "[a-z0-9]" && icon
			let icn = s:i_path.toupper(item).".bmp"
		endif

		let def = printf("sign define SignBookmark%s text='%s texthl=%s %s",
					\ item, item, s:id_hl.Line, ( empty(icn) ? '' : 'icon='.icn))
		call <sid>DefineSignsIcons(def)
	endfor

	" Make Errors (quickfix list)
	if has("quickfix")
		let def = printf("sign define SignQF text=! texthl=%s %s",
				\ s:id_hl.Check, (icon ? " icon=". s:i_path. "arrow-right.bmp" : ''))
		call <sid>DefineSignsIcons(def)
	endif

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

	let s:SignDef = <sid>ReturnSignDef()
endfu

fu! <sid>ReturnDiffSigns() "{{{1
	let fname = expand('%')
	if !executable("diff")	||
		\ empty(fname)		||
		\ !has("diff")		||
		\ !filereadable(fname) 
		" nothing to do
		if &verbose > 0
			call add(s:msg, 'Diff not possible:' . 
				\ (!executable("diff") ? ' No diff executable found!' :
				\ empty(fname) ? ' Current file has never been written!' :
				\ !filereadable(fname) ? ' '. fname. ' not readable!' :
				\ ' Vim was compiled without diff feature!'))
		endif
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
	let contents = getline(1,'$')
	if &ff == 'dos'
		" write dos-files
		call map(contents, 'v:val . nr2char(13)')
	endif
	" Need to convert the data, so that diff won't complain
	if &fenc != &enc && has("iconv")
		call map(contents, 'iconv(v:val, &enc, &fenc)')
	endif
	call writefile(contents, new_file)
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

fu! <sid>DoSigns() "{{{1
	if !s:MixedIndentation &&
		\ get(s:CacheOpts, 'MixedIndentation', 0) > 0
		if exists("s:MixedIndentationHL")
			call matchdelete(s:MixedIndentationHL)
		endif
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

	elseif !s:SignScrollbar &&
		\ get(s:CacheOpts, 'SignScrollbar', 0) > 0
		let index = match(s:Signs, 'id='. s:sign_prefix.
			\ '\d\+.*name=SignScrollbar')
		while index > -1
			let line = matchstr(s:Signs[index], 'line='\zs\d\+\ze\D')
			call <sid>UnplaceSignId(s:sign_prefix.line)
			call remove(s:Signs, index)
			let index = match(s:Signs, 'id='.s:sign_prefix.
				\ '\d\+.*name=SignScrollbar')
		endw
		" remove autocommand
		call <sid>DoSignScrollbarAucmd(0)

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
		\ !s:SignDiff		   &&
		\ s:SignScrollbar)  "return false, when s:SignScrollbar is set
		" update cache
		call <sid>BufferConfigCache()
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
		if exists("s:BookmarkSignsHL")
			for value in values(s:BookmarkSignsHL)
				call matchdelete(value)
				call remove(s:BookmarkSignsHL, value)
			endfor
		endif
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
	let s:CacheOpts.SignScrollbar    = s:SignScrollbar
	let s:CacheOpts.SignHook		 = s:SignHook
	let s:CacheOpts.SignDiff		 = s:SignDiff
	let s:CacheOpts.NoUtf8Signs      = exists("g:NoUtf8Signs") ? g:NoUtf8Signs : 0
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
				try
					exe "sign place " s:sign_prefix . a:line . " line=" .
						\ 	a:line.  " name=".
						\ (indent/div < 10 ? indent/div : '10').
						\ " buffer=" . bufnr('')
				catch
					call add(s:msg, "Error at line: " . a:line)
					if s:debug
						call add(s:msg, v:exception)
					endif
				endtry
			endif
			return 1
		elseif oldSign >= 0
			"no more indentation Signs needed, remove
			call <sid>UnplaceSignSingle(a:line)
		endif
	endif 
	return 0
endfu

fu! <sid>PlaceScrollbarSigns() "{{{1
	" doesn't work well with folded lines, unfortunately
	" Disabled in the gui, only works with +float and when s:SignScrollbar
	" has been configured.
	if exists("s:SignScrollbar") && s:SignScrollbar && has('float')
		if !&lz
			let do_unset_lz = 1
			setl lz
		endif
		if !exists("b:SignScrollbarState")
			let b:SignScrollbarState = 0
		endif
		let curline  = line('.')  + 0.0
		let lastline = line('$')  + 0.0
		"let wheight  = line('w$') - line('w0') + 0.0 
		let wheight  = winheight(0) + 0.0 
		let curperc  = curline/lastline
		let tline    = round(wheight * curperc)
		"if  tline < line('w0')
		"let tline += line('w0') - (curperc >= 0.95 ? 0 : 1)
		let tline += line('w0') - 1
		"endif
		let tline    = float2nr(tline)

		" safety check
		if line('$')  < tline
			let tline = line('$')
		elseif line('w0') > tline
			let tline = line('w0')
		endif

		let nline    = (line('.') > line('$')/2 ? tline-1 : tline+1)

		let _pos     = getpos('.')
		call cursor(1,1)
		if &wrap && search('\%>'.&tw.'c', 'nW') > 0
			" Wrapping occurs, don't display 2 signs
			let wrap = 1
		else
			let wrap = 0
		endif
		call setpos('.', _pos)

		" Place 2 Signs if no wrapping occurs,
		" so the scrollbar looks better
		for line in [tline, nline]
			exe "sign place " s:sign_prefix . b:SignScrollbarState . 
				\ " line=" . string(line) .
				\ " name=SignScrollbar buffer=" . bufnr('')
			if wrap
				break
			endif
		endfor
		let b:SignScrollbarState = !b:SignScrollbarState
		let idx=match(s:Signs, 'id='. s:sign_prefix.
				\ b:SignScrollbarState. '.*name=SignScrollbar')
		while idx > -1
			" unplace old signs
			call <sid>UnplaceSignID(s:sign_prefix. b:SignScrollbarState)
			" update s:Signs
			call remove(s:Signs, idx)
			let idx=match(s:Signs, 'id='. s:sign_prefix.
					\ b:SignScrollbarState. '.*name=SignScrollbar')
		endw
		if exists("do_unset_lz") && do_unset_lz
			setl nolz
			unlet! do_unset_lz
			redraw
		endif
		call <sid>BufferConfigCache()
		return 1
	endif
	return 0
endfu

fu! <sid>PlaceMixedWhitespaceSign(line) "{{{1
	if exists("s:MixedIndentation") &&
				\ s:MixedIndentation == 1

		let line = getline(a:line)
		let pat1 = '\%(^\s\+\%(\t \)\|\%( \t\)\)'
		let pat2 = '\%(\S\zs\s\+$\)'
		"highlight non-breaking space, etc...
		let pat3 = '\%([\x0b\x0c\u00a0\u1680\u180e\u2000-\u200a\u2028\u202f\u205f\u3000\ufeff]\)'
		
		let pat = pat1. '\|'. pat2. '\|'. pat3
		if !exists("s:MixedIndentationHL")
			let s:MixedIndentationHL = 
			\ matchadd('Error', pat)
		endif
		let oldSign = match(s:Signs, 'line='.a:line.
					\ '.*name=SignWSError')
		if match(line, pat) > -1 
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
	if !s:MixedIndentation
		unlet! s:MixedIndentationHL
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
		let oldSign = match(s:Signs, 'line='.a:line. '\D.*name=SignAdded')

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
			return 1
		endif

		" Changed Lines
		let oldSign = match(s:Signs, 'line='. a:line. 
				\ '\D.*name=SignChanged')
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
			return 1
		endif

		" Deleted Lines
		let oldSign = match(s:Signs, 'line='. a:line.
				\ '\D.*name=SignDeleted')
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
	if exists("s:BookmarkSigns")
		\ && s:BookmarkSigns == 1
		let pat = 'id='.s:sign_prefix.'\('.a:line.'\)[^0-9=]*=SignBookmark\(.\)'
		let oldSign = matchlist(s:Signs, pat)
		
		let MarksOnLine = <sid>GetMarksOnLine(a:line)
		if empty(oldSign)
			if !empty(MarksOnLine)
				" Take the first bookmark, that is on that line
				let line = s:bookmarks[MarksOnLine[0]]
				exe "sign place " s:sign_prefix. line.
					\ " line=". line. " name=SignBookmark".
					\ MarksOnLine[0]. " buffer=". bufnr('')
				let s:BookmarkSignsHL[MarksOnLine[0]] = matchadd('WildMenu',
					\ <sid>GetPattern(MarksOnLine[0]))
				return 1
			endif
			return 0
		else
			" Bookmark Sign no longer needed, remove it
			call <sid>UnplaceSignSingle(a:line)
			for mark in <sid>GetMarksOnLine(a:line)
				if has_key(s:BookmarkSignsHL, mark)
					call matchdelete(s:BookmarkSignsHL[mark])
					call remove(s:BookmarkSignsHL, mark)
				endif
			endfor
		endif
	endif
	return 0
endfu

fu! <sid>GetMarksOnLine(line) "{{{1
	return sort(keys(filter(copy(s:bookmarks), 'v:val==a:line')))
endfu

fu! <sid>GetPattern(mark) "{{{1
	let mark = a:mark
	if mark != '.'
		let mark = "'". a:mark
	endif
	let pos = getpos(mark)
	if pos[0] == 0 || pos[0] == bufnr('%')
		return '\%'.pos[1]. 'l\%'.pos[2].'c'
	endif
	return ''
endfu

fu! <sid>UpdateDiffSigns(DiffSigns) "{{{1
	
	if empty(a:DiffSigns)
		" nothing to do
		return
	endif
	let oldSign = match(s:Signs, 
		\ '.*name=Sign\(Added\|Changed\|Deleted\)')
	while oldSign > -1
		call <sid>UnplaceSignSingle(matchstr(s:Signs[oldSign], 'line=\zs\d\+\ze'))
		call remove(s:Signs, oldSign)
		let oldSign = match(s:Signs, 
			\ '.*name=Sign\(Added\|Changed\|Deleted\)')
	endw
	for line in a:DiffSigns['a'] + a:DiffSigns['c'] + a:DiffSigns['d']
		call <sid>PlaceDiffSigns(line, a:DiffSigns)
	endfor
	" TODO: unplace Old DiffSigns
endfu
fu! DynamicSigns#UpdateWindowSigns(ignorepat) "{{{1
	" Only update all signs in the current window viewport
	let _a = winsaveview()
	" remove old matches first...
	call <sid>UnMatchHL()
	if !exists("b:changes_chg_tick")
		let b:changes_chg_tick = 0
	endif
	try
		call <sid>Init()
		let s:old_ignore = s:ignore
		let s:ignore += split(a:ignorepat, ',')
	catch
		call <sid>WarningMsg()
		call winrestview(_a)
		return
	endtry
	" Only update, if there have been changes to the buffer
	if b:changes_chg_tick != b:changedtick
		let b:changes_chg_tick = b:changedtick
		if !s:SignScrollbar
			call <sid>PlaceSigns(line('w0'), line('w$'))
		endif
		" Redraw Screen
		"exe "norm! \<C-L>"
	endif
	if s:SignScrollbar
		call DynamicSigns#UpdateScrollbarSigns()
	endif
	if s:BookmarkSigns
		call <sid>DoBookmarkHL()
	endif
	if s:SignDiff
		try
			let DiffSigns   = (s:SignDiff ? <sid>ReturnDiffSigns() : {})
			call <sid>UpdateDiffSigns(DiffSigns)
		catch /DiffError/
			call <sid>WarningMsg()
		endtry
	endif
	let s:ignore = s:old_ignore
	call winrestview(_a)
endfu

fu! DynamicSigns#UpdateScrollbarSigns() "{{{1
	" When GuiEnter fires, we need to disable the scrollbar signs
	call <sid>Init()
	call <sid>DoSigns()
	call <sid>PlaceScrollbarSigns()
endfu

fu! DynamicSigns#MapBookmark() "{{{1
	let a = getchar()
	if type(a) == type(0)
		let char = nr2char(a)
	else
		let char = a
	endif
	" make sure, this is only called, when Bookmark Signs are enabled
	" Since plugin is possibly not init yet, need to check both variables
	if (exists("s:BookmarkSigns") && s:BookmarkSigns)
		\ || (exists("g:Signs_Bookmarks") && g:Signs_Bookmarks)
		" Initilize variables
		call <sid>Init()
		if <sid>DoSignBookmarks() &&
			\ match(s:SignDef, 'SignBookmark'.char) >= 0  " there was a sign defined for the mark
			" First place the new sign
			" don't unplace old signs first, that prevents flicker (e.g. first
			" removing all signs, removes the sign column, than placing a sign adds
			" the sign column again.
			let cline = line('.')
			let sign_cmd =
				\ printf(":sign place %d%d line=%d name=SignBookmark%s buffer=%d",
				\ s:sign_prefix, cline, cline, char, bufnr(''))
			exe sign_cmd
			let indx = []
			" unplace previous mark for this sign
			let pat = 'id='.s:sign_prefix.'\(\d\+\)[^=]*=SignBookmark\('.char.'\)'
			let indx = matchlist(s:Signs, pat)
			while !empty(indx)
				let line = indx[1]
				let mark = indx[2]
				if getpos('.') != getpos(mark) && mark != char
					call <sid>UnplaceSignID(s:sign_prefix.line)
					sil! call matchdelete(s:BookmarkSignsHL[mark])
					sil! call matchdelete(s:BookmarkSignsHL[char])
				endif

				let index = match(s:Signs, pat)
				call remove(s:Signs, index)
				let indx = matchlist(s:Signs, pat)
			endw
			" Unplace anyhow (in case the while loop didn't run)
			sil! call matchdelete(s:BookmarkSignsHL[char])
			" Mark hasn't been placed yet, so take cursor position
			let s:BookmarkSignsHL[char] = matchadd('WildMenu', <sid>GetPattern('.'))

		endif
		call <sid>BufferConfigCache()
	endif
	return 'm'.char
endfu

fu! DynamicSigns#MapKey() "{{{1
	" Does not work: Error
	" E15: Invalid expression: <80><fd>SDynamicSignsMapBookmark
	" This looks like a bug in vim
	" nnoremap <silent> <expr> <Plug>DynamicSignsMapBookmark DynamicSigns#MapBookmark()
	if !hasmapto('DynamicSigns#MapBookmark', 'n')
		nnoremap <expr> m DynamicSigns#MapBookmark()
	endif
endfu

fu! DynamicSigns#Update() "{{{1
	if exists("s:SignScrollbar") && s:SignScrollbar
		call DynamicSigns#UpdateScrollbarSigns()
	else
		call DynamicSigns#Run(1)
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
	" remove placed highlighting
	call <sid>UnMatchHL()
	" undefine all signs
	if exists("s:SignDef")
		for sign in s:SignDef
			exe "sil! sign undefine" sign
		endfor
	endif
	call <sid>AuCmd(0)
	unlet! s:precheck s:SignDef
endfu

fu! DynamicSigns#PrepareSignExpression(arg) "{{{1
	let g:Signs_Hook = a:arg
	call DynamicSigns#Run()
endfu

fu! <sid>MySortBookmarks(a, b) "{{{¹
	return a:a+0 == a:b+0 ? 0 : a:a+0 > a:b+0 ? 1: -1
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

" Modeline "{{{1
" vim: fdm=marker fdl=0 ts=4 sts=4 com+=l\:\" fdl=0 sw=4
