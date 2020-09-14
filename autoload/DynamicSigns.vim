" DynamicSigns.vim - Using Signs for different things
" ---------------------------------------------------------------
"Author:		Christian Brabandt <cb@256bit.org>
"License:		VIM License (see :h license)
"URL:			http://www.github.com/chrisbra/DynamicSigns
"Documentation:	DynamicSigns.txt
"Version:		0.1
"Last Change: Thu, 15 Mar 2012 23:37:37 +0100
"GetLatestVimScripts:  3965 1 :AutoInstall: DynamicSigns.vim

"{{{1Scriptlocal variables
fu! <sid>GetSID()
	return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_GetSID$')
endfu
" Check preconditions
scriptencoding utf-8
let s:plugin = fnamemodify(expand("<sfile>"), ':t:r')
let s:i_path = fnamemodify(expand("<sfile>"), ':p:h'). '/'. s:plugin. '/'
let s:execute = exists("*execute")
let s:sign_api = v:version > 801 || (v:version == 801 && has("patch614"))
let s:sign_api_group = 'DynamicSigns'

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

	let s:sign_prefix = (s:sign_api ? '' : s:sid)
	let s:id_hl       = {}
	let s:id_hl.Line  = "DiffAdd"
	let s:id_hl.Error = "Error"
	let s:id_hl.Check = "User1"
	let s:id_hl.LineEven = get(g:, "g:DynamicSigns_Even", <sid>Color("Even"))
	let s:id_hl.LineOdd  = get(g:, "g:DynamicSigns_Odd",  <sid>Color("Odd"))
	let s:id_hl.Warning = "WarningMsg"
	let s:id_hl.Mark    = 'DynamicSignsHighlightMarks'

	" highlight line
	" TODO: simplify, a simple `:hi default should work!
	if !hlexists("SignLine1") || empty(synIDattr(hlID("SignLine1"), "ctermbg"))
		exe "hi default SignLine1 ctermbg=238 guibg=#403D3D"
	endif
	if !hlexists("SignLine2") || empty(synIDattr(hlID("SignLine2"), "ctermbg"))
		exe "hi default SignLine2 ctermbg=208 guibg=#FD971F"
	endif
	if !hlexists("SignLine3") || empty(synIDattr(hlID("SignLine3"), "ctermbg"))
		exe "hi default SignLine3 ctermbg=24  guibg=#13354A"
	endif
	if !hlexists("SignLine4") || empty(synIDattr(hlID("SignLine4"), "ctermbg"))
		exe "hi default SignLine4 ctermbg=1  guibg=Red"
	endif
	if !hlexists("SignLine5") || empty(synIDattr(hlID("SignLine5"), "ctermbg"))
		exe "hi default SignLine5 ctermbg=190 guibg=#DFFF00"
	endif
	if !hlexists("DynamicSignsHighlightMarks")
		hi default link DynamicSignsHighlightMarks Visual
	endif

	if exists("+signcolumn")
		let s:unset_signcolumn=1
		set signcolumn=yes
	endif

	" Undefine Signs
	if exists("s:precheck")
		" just started up, there shouldn't be any signs yet
		call DynamicSigns#CleanUp()
	endif
	" Define Signs
	call <sid>DefineSigns()
endfu
fu! <sid>Color(name) "{{{1
	let definition = ''
	let termmode=!empty(&t_Co) && &t_Co < 88 && !&tgc
	if a:name == 'Even'
		if &bg == 'dark'
			if termmode
				let definition .= ' ctermbg=DarkGray'
			else
				let definition .= ' ctermbg='. (&t_Co == 88 ? '80' : '234'). ' guibg=#292929'
			endif
		else
			if termmode
				let definition .= ' ctermbg=LightGrey'
			else
				let definition .= ' ctermbg='. (&t_Co == 88 ? '86' : '245') . ' guibg=#525252'
			endif
		endif
		exe "hi default LineEven" definition
		return 'LineEven'
	else
		if &bg == 'dark'
			if termmode
				let definition .= ' ctermbg=LightGray'
			else
				let definition .= ' ctermbg='. (&t_Co == 88 ? '86' : '245') . ' guibg=#525252'
			endif
		else
			if termmode
				let definition .= ' ctermbg=LightGrey'
			else
				let definition .= ' ctermbg='. (&t_Co == 88 ? '80' : '234') . ' guibg=#292929'
			endif
		endif
		exe "hi default LineOdd" definition
		return 'LineOdd'
	endif
endfu
fu! <sid>WarningMsg() "{{{1
	redraw!
	if !empty(s:msg)
		let msg=["Signs.vim: " . s:msg[0]] + (len(s:msg) > 1 ? s:msg[1:] : [])
		echohl WarningMsg
		for mess in msg
			exe s:echo_cmd "mess"
		endfor
		echohl Normal
		let s:msg=[]
	endif
endfu
fu! <sid>Init(...) "{{{1
	" Message queue, that will be displayed.
	let s:msg  = []

	" Setup configuration variables:
	let s:MixedIndentation = get(g:, "Signs_MixedIndentation", 0)
	let s:IndentationLevel = get(g:, "Signs_IndentationLevel", 0)
	let s:BookmarkSigns    = get(g:, "Signs_Bookmarks", 0)
	let s:AlternatingSigns = get(g:, "Signs_Alternate", 0)
	let s:SignHook         = get(w:, "Signs_Hook", "")
	let s:SignQF           = get(g:, "Signs_QFList", 0)
	let s:SignDiff         = get(g:, "Signs_Diff", 0)
	let s:Bookmarks = split("abcdefghijklmnopqrstuvwxyz" .
				\ "ABCDEFGHIJKLMNOPQRSTUVWXYZ", '\zs')

	" Don't draw an ascii scrollbar in the gui, because it does not look nice
	" and the gui can display its own scrollbar
	let s:SignScrollbar = get(g:, "Signs_Scrollbar", 0) && !has("gui_running")

	let s:Sign_CursorHold = get(g:, "Signs_CursorHold", 0)
	let s:debug    = get(g:, "Signs_Debug", 0)
	let s:ignore   = split(get(g:, 'Signs_Ignore', ''), ',')

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
	if get(g:, "NoUtf8Signs", 0) != get(s:CacheOpts, 'NoUtf8Signs', 0)
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
fu! <sid>NextID() "{{{1
	" Not used for sign api
	let b:sign_count= get(b:, 'sign_count', 0) + 1
	return (s:sign_prefix . b:sign_count) + 0
endfu
fu! <sid>ReturnSignDef() "{{{1
	if s:sign_api
		return filter(sign_getdefined(), {i,v -> v.name =~ '^DSign'})
	endif
	let a = <sid>Redir(':sil sign list')
	let b = split(a, "\n")[2:]
	call map(b, 'split(v:val)[1]')
	return filter(b, 'v:val=~''^DSign''')
endfu
fu! <sid>ReturnSigns(buffer) "{{{1
	if s:sign_api
		return sign_getplaced(a:buffer, {'group': s:sign_api_group})[0].signs
	endif
	let lang=v:lang
	if lang isnot# 'C'
		sil lang mess C
	endif
	let a = <sid>Redir(':sil sign place buffer='.a:buffer)
	let b = split(a, "\n")[2:]
	" Remove old deleted Signs
	call <sid>RemoveDeletedSigns(filter(copy(b),
		\ 'matchstr(v:val, ''deleted'')'))
	call filter(b, 'matchstr(v:val, ''id=\zs''.s:sign_prefix.''\d\+'')')
	if lang != 'C'
		exe "sil lang mess" lang
	endif
	return b
endfu
fu! <sid>RemoveDeletedSigns(list) "{{{1
	" not used for sign_api
	" but just in case
	if s:sign_api
		call add(s:msg, 'Using wrong function for Sign-API')
		call <sid>WarningMsg()
		return
	endif
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
			au GUIEnter * call DynamicSigns#ForceUpdate()
			au BufWinEnter,VimEnter *
				\ call DynamicSigns#UpdateWindowSigns('')
			au BufWritePost *
				\ call DynamicSigns#UpdateWindowSigns('marks')
			exe s:SignQF ?
				\ "au QuickFixCmdPost * :call DynamicSigns#QFSigns()" : ''
			if exists("s:Sign_CursorHold") && s:Sign_CursorHold
				au CursorHold,CursorHoldI *
					\ call DynamicSigns#UpdateWindowSigns('marks')
			endif
			" make sure, sign expression is reevaluated on changes to
			" the buffer
			au TextChanged * call DynamicSigns#UpdateWindowSigns('diff,marks,indentation')
			au CursorMoved * call DynamicSigns#UpdateWindowSigns('diff,whitespace')
		augroup END
	else
		augroup Signs
			autocmd!
		augroup END
		augroup! Signs
		if exists("#CustomSignExpression")
			augroup CustomSignExpression
				au!
			augroup end
			augroup! CustomSignExpression
		endif
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
fu! <sid>Redir(args) "{{{1
	if s:execute
		let a=execute(a:args)
	else
		redir => a | exe a:args |redir end
	endif
	return a
endfu
fu! <sid>UnPlaceSigns() "{{{1
	if s:sign_api
		call sign_unplace(s:sign_api_group, {'buffer': bufnr('')})
		return
	endif
	let a = <sid>Redir(':sil sign place buffer='.bufnr(''))
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
		sil! call matchdelete(s:MixedIndentationHL)
	endif
	let s:BookmarkSignsHL = {}
endfu
fu! <sid>DoBookmarkHL() "{{{1
	if get(s:, "BookmarkSigns", 0)
		if !exists("s:BookmarkSignsHL")
			let s:BookmarkSignsHL = {}
		endif
		let PlacedSigns = copy(s:Signs)
		if s:sign_api
			call filter(PlacedSigns, {i,v -> v.name =~ 'DSignBookmark\(.\)'})
			call map(PlacedSigns, {i,v -> matchadd(s:id_hl.Mark, <sid>GetPattern(v.name[-1]))})
			return
		endif
		let PlacedSigns = copy(s:Signs)
		let pat = 'id='.s:sign_prefix.'\d\+[^0-9=]*=DSignBookmark\(.\)'
		let Sign = matchlist(PlacedSigns, pat)
		while (!empty(Sign))
			let s:BookmarkSignsHL[Sign[1]] = matchadd(s:id_hl.Mark,
						\ <sid>GetPattern(Sign[1]))
			call remove(PlacedSigns, match(PlacedSigns, pat))
			let Sign = matchlist(PlacedSigns, pat)
		endw
	endif
endfu
fu! <sid>GetLineForSign(sign) "{{{1
	" not used for Sign-API
	return matchstr(a:sign, '^\s*\w\+=\zs\d\+\ze\D') + 0
endfunction
fu! <sid>UnplaceSignSingle(sign) "{{{1
	if s:sign_api
		call sign_unplace(s:sign_api_group, {'buffer': bufnr(''), 'id': a:sign.id})
		return
	endif
	let line = <sid>GetLineForSign(a:sign)
	if line <= 0
		return
	endif
	let oldcursor = winsaveview()
	call cursor(line, 0)
	" Vim errors, if the line does not contain a sign
	sil! sign unplace
	call winrestview(oldcursor)
endfu
fu! <sid>PlaceSignSingle(line, name, ...) "{{{1
	" safety check
	if a:line == 0
		return
	endif
	" Places a single sign
	let bufnr=get(a:000, 0, bufnr(''))
	if s:sign_api
		call sign_place(0, s:sign_api_group, a:name, bufnr, {'lnum': a:line})
	else
		exe "sign place ". <sid>NextID(). " line=" . a:line.  " name=". a:name.  " buffer=" . bufnr
	endif
endfu
fu! <sid>SignName(sign)
	if s:sign_api
		return a:sign.name
	else
		return matchstr(a:sign, 'name=\zs\S\+\ze')
	endif
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
				" Evaluating expression failed, avoid
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
fu! <sid>GetSignDef(def) "{{{1
	" Returns sign definition as string for use as `:sign command`
	" not used when s:sign_api is defined
	return (has_key(a:def, 'text') ? ' text='.get(a:def, 'text', '') : '').
		\ (has_key(a:def, 'texthl') ? ' texthl='.get(a:def, 'texthl', '') : '').
		\ (has_key(a:def, 'icon') ? ' icon='.get(a:def, 'icon', '') : '').
		\ (has_key(a:def, 'linehl') ? ' linehl='.get(a:def, 'linehl', '') : '')
endfu
fu! <sid>DefineSignIcons(def) "{{{1
	for def in keys(a:def)
		if s:sign_api
			let sign = a:def[def]
			try
				call sign_define(def, sign)
			catch /^Vim\%((\a\+)\)\=:E255/
				" gvim can't read the icon
				" first undefine the sign
				call remove(sign, 'icon')
				call sign_define(key, sign)
			endtry
			continue
		endif
		try
			let cmd="sign define ". def. <sid>GetSignDef(a:def[def])
			let path=matchstr(cmd, 'icon=\zs\S*')
			if !filereadable(path)
				let cmd=substitute(cmd, 'icon=\S*', '', '')
			endif
			exe cmd
		catch /^Vim\%((\a\+)\)\=:E255/
			" gvim can't read the icon
			" first undefine the sign
			exe "sign undefine" matchstr(cmd, '^sign define \zs\S\+\ze')
			" redefine the sign without an icon
			exe substitute(cmd, 'icon=.*$', '', '')
		endtry
	endfor
endfu
fu! <sid>DefineSigns() "{{{1
	let icon = 0
	if (has("gui_gtk") || has("gui_win32") || has("win32") || has("win64"))
		\ && has("gui_running")
		let icon = 1
	endif

	let utf8signs = get(g:, "NoUtf8Signs", 1)

	if utf8signs && &enc != 'utf-8'
		let utf8signs = 0
	endif
	let def = {}

	" Indentlevel
	for item in range(1,9)
		let def["DSign".item] = {
					\ 'text': item,
					\ 'texthl': s:id_hl.Line,
					\ 'icon': icon ? (s:i_path. item. '.bmp') : ''}
	endfor

	" Indentlevel > 9
	let def["DSign10"] = {
					\ 'text': ">9",
					\ 'texthl': s:id_hl.Error,
					\ 'icon': icon ? (s:i_path. 'error.bmp') : ''}

	" Indentlevel < 1
	let def["DSign0"] = {
					\ 'text': "<1",
					\ 'texthl': s:id_hl.Warning,
					\ 'icon': icon ? (s:i_path. 'warning.bmp') : ''}

	" Mixed Indentation Error
	let def["DSignWSError"] = {
					\ 'text': "X",
					\ 'texthl': s:id_hl.Error,
					\ 'icon': icon ? (s:i_path. 'error.bmp') : ''}

	" Scrollbar
	let def["DSignScrollbar"] = {
					\ 'text': (utf8signs ? '██': '>>'),
					\ 'texthl': s:id_hl.Check}

	" Custom Signs Hooks
	for sign in ['OK', 'Warning', 'Error', 'Info', 'Add', 'Arrow', 'Flag', 'Delete', 'Stop']
				\ + ['Line1', 'Line2', 'Line3', 'Line4', 'Line5']
				\ + ['Gutter1', 'Gutter2', 'Gutter3', 'Gutter4', 'Gutter5']
				\ + range(1,99)
		let icn  = (icon ? s:i_path : '')
		let text = ""
		let texthl = ''
		let line = 0
		if sign =~# '^\d\+$'
			let icn  = ''
			let text = sign
			let texthl = 'Normal'
		elseif sign ==     'OK'
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
		elseif sign =~# 'Line\d'
			let icn  = ''
			let line = matchstr(sign, 'Line\zs\d')+0
			let texthl = 'Normal'
		elseif sign =~# 'Gutter\d'
			let icn  = ''
			let text = "\u00a0"
			let texthl = 'SignLine'. matchstr(sign, 'Gutter\zs\d')+0
		endif
		let def["DSignCustom".sign] = {
					\ 'texthl': (empty(texthl) ? s:id_hl.Error : texthl)}
		if !empty(text)
			let def["DSignCustom".sign]["text"] = text
		endif
		if !empty(icn)
			let def["DSignCustom".sign]["icon"] = icn
		endif
		if line
			let def["DSignCustom".sign]["linehl"] = "SignLine". line
		endif
	endfor

	" Bookmark Signs
	for item in s:Bookmarks
		let icn = ''
		if item =~# "[a-z0-9]" && icon
			let icn = s:i_path.toupper(item).".bmp"
		endif
		let def["DSignBookmark".item] = {
					\ 'text': "'".item,
					\ 'texthl': s:id_hl.Line,
					\ 'icon': icn }
	endfor

	" Make Errors (quickfix list)
	if has("quickfix")
		let def["DSignQF"] = {
					\ 'text': "!",
					\ 'texthl': s:id_hl.Check,
					\ 'icon': (icon ? s:i_path. "arrow-right.bmp" : '')}
	endif

	" Diff Signs
	if has("diff")
		let def["DSignAdded"] = {
					\ 'text': "+",
					\ 'texthl': 'DiffAdd',
					\ 'icon': (icon ? s:i_path. "add.bmp" : '')}
		let def["DSignChanged"] = {
					\ 'text': "M",
					\ 'texthl': 'DiffAdd',
					\ 'icon': (icon ? s:i_path. "warning.bmp" : '')}
		let def["DSignDeleted"] = {
					\ 'text': "-",
					\ 'texthl': 'DiffDeleted',
					\ 'icon': (icon ? s:i_path. "delete.bmp" : '')}
	endif

	" Alternating Colors
	let def["DSignEven"] = {
				\ 'linehl': s:id_hl.LineEven}
	let def["DSignOdd"] = {
				\ 'linehl': s:id_hl.LineOdd}

    for name in keys(def)
      " remove empty keys from dictionary
		if v:version >= 800
			call filter(def[name], {key, val -> !empty(val)})
		else
			call filter(def[name], '!empty(v:val)')
		endif
    endfor
	" Check for all the defined signs for accessibility of the icon
	" and define the signs then finally
	call <sid>DefineSignIcons(def)

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
	let result = systemlist(cmd)

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
	if !exists("b:dynamicsigns_tick")
		let b:dynamicsigns_tick = 0
	endif
	" Only update, if there have been changes to the buffer
	if b:dynamicsigns_tick != b:changedtick || a:force
		call DynamicSigns#Run()
		let b:dynamicsigns_tick = b:changedtick
	endif
endfu
fu! <sid>SignNameMatchesAny(pat) "{{{1
	" just check there exists any sign with
	" the given name, regardless of the line
	return <sid>SignNameMatches(a:pat, 0)
endfu
fu! <sid>SignNameMatches(pat, line) "{{{1
	" Return signs whose name matches pattern
	let line = a:line == 0 ? -1 : a:line
	if s:sign_api
		let id=0
		for sign in s:Signs
			if sign.name =~ a:pat && (line == -1 || sign.lnum == a:line)
				return id
			endif
			let id+=1
		endfor
		return -1
		" foobar
	else
		let idx1 = match(s:Signs, a:pat)
		if idx1 > -1
			if (line == -1)
				return idx1
			else
				return match(s:Signs, 'line='.a:line.'\D.*'. a:pat)
			endif
		endif
	endif
	return -1
endfu
fu! <sid>SignPattern(name) "{{{1
	" Generate a pattern that can be used for <sid>SignNameMatches
	if s:sign_api
		return a:name
	else
		return 'id='.s:sign_prefix.'\d\+.*='.a:name
	endif
endfu
fu! <sid>DoSigns() "{{{1
	" Returns true, if signs need to be processed by this plugin
	if !s:MixedIndentation &&
		\ get(s:CacheOpts, 'MixedIndentation', 0) > 0
		if exists("s:MixedIndentationHL")
			call matchdelete(s:MixedIndentationHL)
		endif
		let pat = <sid>SignPattern('DSignWSError')
		let index = <sid>SignNameMatchesAny(pat)
		while index > -1
			call <sid>UnplaceSignSingle(s:Signs[index])
			call remove(s:Signs, index)
			let index = <sid>SignNameMatchesAny(pat)
		endw

	elseif !s:IndentationLevel &&
		\ get(s:CacheOpts, 'IndentationLevel', 0) > 0
		let pat = <sid>SignPattern('DSign\d\+')
		let index = <sid>SignNameMatchesAny(pat)
		while index > -1
			call <sid>UnplaceSignSingle(s:Signs[index])
			call remove(s:Signs, index)
			let index = <sid>SignNameMatchesAny(pat)
		endw

	elseif !s:SignHook &&
		\ get(s:CacheOpts, 'SignHook', 0) > 0
		let pat = <sid>SignPattern('DSignCustom')
		let index = <sid>SignNameMatchesAny(pat)
		while index > -1
			call <sid>UnplaceSignSingle(s:Signs[index])
			call remove(s:Signs, index)
			let index = <sid>SignNameMatchesAny(pat)
		endw

	elseif !s:SignScrollbar &&
		\ get(s:CacheOpts, 'SignScrollbar', 0) > 0
		let pat = <sid>SignPattern('DSignScrollbar')
		let index = <sid>SignNameMatchesAny(pat)
		while index > -1
			call <sid>UnplaceSignSingle(s:Signs[index])
			call remove(s:Signs, index)
			let index = <sid>SignNameMatchesAny(pat)
		endw
		" remove autocommand
		call <sid>DoSignScrollbarAucmd(0)

	elseif !s:SignDiff &&
		\ get(s:CacheOpts, 'SignDiff', 0) > 0
		let pat = <sid>SignPattern('DSign\(Add\|Change\|Delete\)')
		let index = <sid>SignNameMatchesAny(pat)
		while index > -1
			call <sid>UnplaceSignSingle(s:Signs[index])
			call remove(s:Signs, index)
			let index = <sid>SignNameMatchesAny(pat)
		endw
	endif
	call <sid>DoSignBookmarks()

	if (  !s:MixedIndentation  &&
		\ !s:IndentationLevel  &&
		\ !s:BookmarkSigns	   &&
		\ !s:SignHook		   &&
		\ !s:SignDiff		   &&
		\ !s:AlternatingSigns  &&
		\ !s:SignScrollbar)  "return false, when s:SignScrollbar is set
		" update cache
		call <sid>BufferConfigCache()
		return 0
	else
		return 1
	endif
endfu
fu! <sid>DoSignBookmarks() "{{{1
	if s:BookmarkSigns != get(s:CacheOpts, 'BookmarkSigns', 0)
		let pat = <sid>SignPattern('DSignBookmark')
		let index = <sid>SignNameMatchesAny(pat)
		while index > -1
			call <sid>UnplaceSignSingle(s:Signs[index])
			call remove(s:Signs, index)
			let index = <sid>SignNameMatchesAny(pat)
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
	let s:CacheOpts.AlternatingSigns = s:AlternatingSigns
	let s:CacheOpts.NoUtf8Signs      = get(g:, "NoUtf8Signs", 0)
endfu
fu! <sid>PlaceIndentationSign(line) "{{{1
	if get(s:, "IndentationLevel", 0)
		let indent = indent(a:line)
		let div    = shiftwidth()

		let pat = <sid>SignPattern('DSign\d\+')
		let index = <sid>SignNameMatches(pat, a:line)
		if div > 0 && indent > 0
			if index < 0
				try
					let name = 'DSign'. (indent/div < 10 ? indent/div : '10')
					call <sid>PlaceSignSingle(a:line, name)
				catch
					call add(s:msg, "Error placing Indtation sign at line: " . a:line)
					if s:debug
						call add(s:msg, v:exception)
					endif
				endtry
			endif
			return 1
		elseif index >= 0
			"no more indentation Signs needed, remove
			call <sid>UnplaceSignSingle(s:Signs[index])
		endif
	endif
	return 0
endfu
fu! <sid>PlaceScrollbarSigns() "{{{1
	" doesn't work well with folded lines, unfortunately
	" Disabled in the gui, only works with +float and when s:SignScrollbar
	" has been configured.
	if get(s:, "SignScrollbar", 0) && has('float')
		if !&lz
			let do_unset_lz = 1
			setl lz
		endif
		let curline  = line('.')  + 0.0
		let lastline = line('$')  + 0.0
		let wheight  = winheight(0) + 0.0
		let curperc  = curline/lastline
		let tline    = float2nr(round(wheight * curperc) + line('w0') -1)

		" safety check
		if line('$')  < tline
			let tline = line('$')
		elseif line('w0') > tline
			let tline = line('w0')
		endif

		if (line('.') > line('$')/2 && tline > 1)
			let nline = tline - 1
		else
			let nline = tline + 1
		endif

		let wrap = search('\%>'. &tw. 'c', 'nW')
		if &wrap && index([nline, tline], wrap) > -1
			" Wrapping occurs, don't display 2 signs
			let wrap = 1
		else
			let wrap = 0
		endif

		" Place 2 Signs if no wrapping occurs,
		" so the scrollbar looks better
		for line in [tline, nline]
			call <sid>PlaceSignSingle(line, 'DSignScrollbar')
			if wrap
				break
			endif
		endfor
		let pat = <sid>SignPattern('DSignScrollbar')
		let index = <sid>SignNameMatchesAny(pat)
		while index > -1
			" unplace old signs
			call <sid>UnplaceSignSingle(s:Signs[index])
			" update s:Signs
			call remove(s:Signs, index)
			let index = <sid>SignNameMatchesAny(pat)
		endw
		if exists("do_unset_lz") && do_unset_lz
			setl nolz
			unlet! do_unset_lz
		endif
		call <sid>BufferConfigCache()
		return 1
	endif
	return 0
endfu
fu! <sid>PlaceMixedWhitespaceSign(line) "{{{1
	if get(s:, "MixedIndentation", 0)
		let line = getline(a:line)
		if !exists("s:MixedWhitespacePattern")
			let pat1 = '\%(^\s\+\%(\t \)\|\%( \t\)\)'
			let pat2 = '\%(\S\zs\s\+$\)'
			"highlight non-breaking space, etc...
			let pat3 = '\%([\x0b\x0c\u00a0\u1680\u180e\u2000-\u200a\u2028\u202f\u205f\u3000\ufeff]\)'

			let s:MixedWhitespacePattern = pat1. '\|'. pat2. '\|'. pat3
		endif
		if !exists("s:MixedIndentationHL")
			let s:MixedIndentationHL = matchadd('Error', s:MixedWhitespacePattern)
		endif
		let pat = <sid>SignPattern('DSignWSError')
		let index = <sid>SignNameMatches(pat, a:line)
		if match(line, s:MixedWhitespacePattern) > -1
			if index < 0
				call <sid>PlaceSignSingle(a:line, 'DSignWSError')
			endif
			return 1
		elseif index >= 0
			" No more wrong indentation, remove sign
			call <sid>UnplaceSignSingle(s:Signs[index])
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
				\ 'Delete\|Stop\|Line\d\|Gutter\d\|\d\+')
			if empty(result)
				let result = 'Info'
			endif
			let pat = <sid>SignPattern('DSignCustom')
			let index = <sid>SignNameMatches(pat, a:line)
			if !empty(a)
				if index > -1
					let oldSignname = matchstr(<sid>SignName(s:Signs[index]), 'DSignCustom\zs\S\+\ze')
					" need to unplace old signs
					if oldSignname !=# result
						call <sid>UnplaceSignSingle(s:Signs[index])
					else
						return 1
					endif
				endif
				call <sid>PlaceSignSingle(a:line, 'DSignCustom'.result)
			elseif index >= 0
				" Custom Sign no longer needed, remove it
				call <sid>UnplaceSignSingle(s:Signs[index])
				return 0
			endif
			return 1
		catch
			let s:SignHook = ''
			call add(s:msg, 'Error evaluating SignExpression at '. a:line)
			call add(s:msg, v:exception)
			call <sid>WarningMsg()
			return -1
		endtry
	endif
endfu
fu! <sid>PlaceDiffSigns(line, DiffSigns) "{{{1
	" Diff Signs
	let did_place_sign = 0
	if !empty(a:DiffSigns) && !empty(a:DiffSigns['a'] + a:DiffSigns['c'] + a:DiffSigns['d'])
		let pat = <sid>SignPattern('DSignAdded')
		let index = <sid>SignNameMatches(pat, a:line)
		" Added Lines
		let target=index(a:DiffSigns['a'], a:line)
		if target > -1
			if index < 0
				call <sid>PlaceSignSingle(a:line, 'DSignAdded')
			endif
			let did_place_sign = 1
		endif
		if did_place_sign
			return 1
		endif
		" Changed Lines
		let pat = <sid>SignPattern('DSignChanged')
		let index = <sid>SignNameMatches(pat, a:line)
		let target=index(a:DiffSigns['c'], a:line)
		if target > -1
			if index < 0
				call <sid>PlaceSignSingle(a:line, 'DSignChanged')
			endif
			let did_place_sign = 1
		endif
		if did_place_sign
			return 1
		endif
		" Deleted Lines
		let pat = <sid>SignPattern('DSignDeleted')
		let index = <sid>SignNameMatches(pat, a:line)
		let target=index(a:DiffSigns['d'], a:line)
		if target > -1
			if index < 0
				call <sid>PlaceSignSingle(a:line, 'DSignDeleted')
			endif
			let did_place_sign = 1
		endif
		if did_place_sign
			return 1
		endif

		let index = <sid>SignNameMatches(<sid>SignPattern('DSign\([ACD]\)'), a:line)
		if index > -1
			" Diff Sign no longer needed, remove it
			call <sid>UnplaceSignSingle(s:Signs[index])
		endif
	endif
	return 0
endfu
fu! <sid>PlaceAlternatingSigns(line) "{{{1
	if !s:AlternatingSigns
		return 0
	endif
	let pat = <sid>SignPattern('DSignScrollbar')
	let suffix = (a:line %2 ? 'Odd' : 'Even')
	let index1 = <sid>SignNameMatches(<sid>SignPattern('DSign'. suffix), a:line)
	let index2 = <sid>SignNameMatches(<sid>SignPattern('DSign'), a:line)
	if index1 == -1
		if index2 > -1
			" unplace previously place sign first
			call <sid>UnplaceSignSingle(s:Signs[index2])
		endif
		call <sid>PlaceSignSingle(a:line, 'DSign'.suffix)
		return 1
	endif
	return 0
endfu
fu! <sid>PlaceBookmarks(line) "{{{1
	" Place signs for bookmarks
	if get(s:, "BookmarkSigns", 0)
		let MarksOnLine = <sid>GetMarksOnLine(a:line)
		if !empty(MarksOnLine)
			let mark = MarksOnLine[0]
			let name = 'DSignBookmark'.mark
			let pat = <sid>SignPattern(name)
			let index = <sid>SignNameMatches(pat, a:line)
			if index > -1
				" Mark Sign no longer needed, remove it
				call <sid>UnplaceSignSingle(s:Signs[index])
			endif
			call <sid>PlaceSignSingle(a:line, name)
			let s:BookmarkSignsHL[mark] = matchadd(s:id_hl.Mark, <sid>GetPattern(mark))
			return 1
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
	" TODO: - instead of unplacing all signs first and
	"         then placing the new signs, move existing
	"         signs around
	let pat = <sid>SignPattern('DSign\(Added\|Changed\|Deleted\)')
	let index = <sid>SignNameMatchesAny(pat)
	while index > -1
		call <sid>UnplaceSignSingle(s:Signs[index])
		call remove(s:Signs, index)
		let index = <sid>SignNameMatchesAny(pat)
	endw
	for line in a:DiffSigns['a'] + a:DiffSigns['c'] + a:DiffSigns['d']
		call <sid>PlaceDiffSigns(line, a:DiffSigns)
	endfor
endfu
fu! DynamicSigns#UpdateWindowSigns(ignorepat) "{{{1
	" Only update all signs in the current window viewport
	" if no signs have been placed, return early
	if !exists("s:Signs")
		let s:Signs=<sid>ReturnSigns(bufnr(''))
	endif
	if empty(s:Signs)
		return
	endif
	let _a = winsaveview()
	" remove old matches first...
	call <sid>UnMatchHL()
	if !exists("b:dynamicsigns_tick")
		let b:dynamicsigns_tick = 0
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
	" or force parameter is set
	if b:dynamicsigns_tick != b:changedtick
		let b:dynamicsigns_tick = b:changedtick
		" only run for at max 200 lines
		if !s:SignScrollbar && line('w$') - line('w0')  <= 200
			call <sid>PlaceSigns(line('w0'), line('w$'))
		endif
	endif
	if s:SignScrollbar
		call DynamicSigns#UpdateScrollbarSigns()
	endif
	if s:SignHook && !empty(get(w:, 'Signs_Hook', ''))
		let s:ignore = ['alternate', 'diff', 'marks', 'whitespace', 'indentation']
		exe printf(":%d,%dfolddoopen :call <snr>%d_PlaceSignHook(line('.'))",
			\ line('w0'), line('w$'), s:sid)
		"call DynamicSigns#Run()
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
	if s:AlternatingSigns
		call <sid>PlaceSigns(line('w0'), line('w$'))
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
	if get(s:, "BookmarkSigns", 0) || get(g:, "Signs_Bookmarks", 0)
		" Initilize variables
		call <sid>Init()
		if <sid>DoSignBookmarks() && index(s:Bookmarks, char) > -1
			let name = 'DSignBookmark'.char
			let cline = line('.')
			let index = <sid>SignNameMatchesAny(<sid>SignPattern(name))
			" there was a sign defined for the mark
			" First place the new sign
			" don't unplace old signs first, that prevents flicker (e.g. first
			" removing all signs, removes the sign column, than placing a sign adds
			" the sign column again.
			call <sid>PlaceSignSingle(cline, name)
			let indx = []
			" unplace previous mark for this sign
			let index = <sid>SignNameMatchesAny(<sid>SignPattern(name))
			while index > -1
				call <sid>UnplaceSignSingle(s:Signs[index])
				call remove(s:Signs, index)
				let index = <sid>SignNameMatchesAny(<sid>SignPattern(name))
			endw
			" Refresh highlighting
			sil! call matchdelete(s:BookmarkSignsHL[char])
			" Mark hasn't been plRefresh highlighting
			let s:BookmarkSignsHL[char] = matchadd(s:id_hl.Mark, <sid>GetPattern('.'))
			" Refresh highlighting
			call <sid>BufferConfigCache()
		endif
	endif
	return 'm'.char
endfu
fu! DynamicSigns#Update(...) "{{{1
	if exists("s:SignScrollbar") && s:SignScrollbar
		call DynamicSigns#UpdateScrollbarSigns()
	else
		call DynamicSigns#Run(0, line('w0'), line('w$'))
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
	if exists("a:2") && exists("a:3")
		" only update signs in current window
		" e.g. :UpdateSigns has been called
		call <sid>PlaceSigns(a:2, a:3)
	else
		call <sid>PlaceSigns()
	endif
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
			if s:sign_api
				call sign_undefine(sign.name)
			else
				exe "sil! sign undefine" sign
			endif
		endfor
	endif
	call <sid>AuCmd(0)
	if exists("s:unset_signcolumn")
		set signcolumn=auto
	endif
	unlet! s:precheck s:SignDef s:unset_signcolumn
	redraw!
endfu
fu! DynamicSigns#PrepareSignExpression(arg) "{{{1
	let w:Signs_Hook = a:arg
	call <sid>Init()
	let old_ignore = s:ignore
	" only update the sign expression
	let s:ignore = ['alternate', 'diff', 'marks', 'whitespace', 'indentation']
	call DynamicSigns#Run()
	let s:ignore = old_ignore
endfu
fu! DynamicSigns#SignsQFList(local) "{{{1
	if !has("quickfix")
		return
	endif
	call <sid>Init()
	let qflist = []
	if s:sign_api
		for sign in sign_getplaced()
			if empty(sign.signs)
				continue
			endif
			for item in sign.signs
				call add(qflist, {'bufnr': sign.bufnr, 'lnum':item.lnum,
							\ 'text': getbufline(sign.bufnr, item.lnum)})
			endfor
		endfor
	else
		let a = <sid>Redir(':sil sign place')
		for sign in split(a, "\n")
			if match(sign, '^Signs for \(.*\):$') >= 0
				let fname = matchstr(sign, '^Signs for \zs.*\ze:$')
				let file  = readfile(fname)
			elseif match(sign, '^\s\+\w\+=\d\+\s') >= 0
				let line = matchstr(sign, '^\s*\w\+=\zs\d\+\ze\s')
				call add(qflist, {'filename': fname, 'lnum': line,
					\ 'text': file[line-1]})
			else
				continue
			endif
		endfor
	endif
	if a:local
		let func = 'setloclist'
		let args = [0, qflist]
		let open = 'lopen'
	else
		let func = 'setqflist'
		let args = [qflist]
		let open = 'copen'
	endif
	let s:no_qf_autocmd = 1
	call call(func, args)
	unlet s:no_qf_autocmd
	exe open
endfu
fu! DynamicSigns#ForceUpdate() "{{{1
	call <sid>UpdateView(1)
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
			if item.bufnr == 0
				continue
			endif
			call <sid>PlaceSignSingle(item.lnum, 'DSignQF', item.bufnr)
		endfor
	endif
endfu
" Modeline "{{{1
" vim: fdm=marker fdl=0 ts=4 sts=4 com+=l\:\" fdl=0 sw=4 noet
