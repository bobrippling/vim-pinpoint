let s:preview_winid = -1
let s:saved_laststatus = &laststatus
let s:restore_win_layout = ''
let s:current_list = []
let s:current_ent = ""
let s:current_ent_slashcount = 0
let s:current_mode = 'f'
let s:timer = -1
let s:showre = 0

function! s:GetRe(pat) abort
	let pat = a:pat

	if pat[0] ==# '~'
		" match s:MatchingBufs and always expand ~
		let pat = expand(pat)
	endif

	"let pat = substitute(pat, '.', '*&', 'g')
	"let pat = glob2regpat("*" . pat . "*")

	"let pat = substitute(pat, '[.*]', '\\&', 'g')
	"let pat = substitute(pat, '[^\].', '&.\\{-}', 'g')

	" escape: . * [ ] \ & ~
	let to_escape = '\ze[][.*&\\~]'
	let parts = split(pat, to_escape)
	let result = []
	for i in range(len(parts))
		let part = parts[i]
		if i > 0
			call add(result, '\' . part[0])
			let part = part[1:]
		endif

		call add(result, substitute(part, '.', '&.\\{-}', 'g'))
	endfor

	let re = join(result, '')
	if &ignorecase && (!&smartcase || !s:ismixedcase(re))
		let re = '\c' . re
	else
		let re = '\C' . re
	endif
	return re
endfunction

function! s:ismixedcase(str) abort
	return tolower(a:str) !=# a:str
endfunction

function! s:slashcount(s) abort
	return len(substitute(a:s, '[^/]', '', 'g'))
endfunction

function! s:slashcount_relevant(mode) abort
	return stridx("fo", a:mode) >= 0
endfunction

function! s:globpath_for_pattern(pat) abort
	let pat = a:pat

	let no_glob_start = stridx("/.", pat[0]) >= 0

	if g:pinpoint_preview_fullwords
		" instead of s/fron/abc --> *s*/*f*r*o*n*/*a*b*c*
		" do:                   --> *s*/*fron*/*abc*
		let globpath = substitute(pat, '/', '*/*', 'g') . '*'
		let globpath = substitute(globpath, '\*\*\+', '*', 'g')
	else
		let globpath = substitute(pat, ".", "&*", "g")
	endif

	if no_glob_start
		let globpath = substitute(globpath, '^\*\+', '', '')
	endif

	" handle dotfiles
	let globpath = substitute(globpath, '/\*\.', '/.', 'g')

	" handle ~
	let globpath = substitute(globpath, '\~\*/', '~/', 'g')

	return globpath
endfunction

function! pinpoint#ShowWithMode(mode)
	let s:current_mode = a:mode

	return ":\<C-U>Pinpoint "
endfunction

function! s:resolve_mode(mode, cmdline)
	if a:mode ==# "p"
		return [s:current_mode, a:cmdline]
	else
		return [a:mode, a:cmdline]
	endif

	" vscode ctrl-p behaviour:
	"  key      prompt/shortcut from <C-P>  desc
	" `<C-P>`                               file nav
	" `<C-R>`                               recent nav
	" `<C-S-P>`      >                      command palette, e.g. ???
	" `<C-S-O>`      #, @-for-file          goto symbol
	" `<C-G>`        :                      goto line
	" `<C-S-M>`                             goto problems/quickfix
	" `\``                                  toggle terminal
endfunction

function! s:MatchingBufs(pat, list, mode) abort
	let pat = a:pat
	let [mode, pat] = s:resolve_mode(a:mode, pat)

	let re = s:GetRe(pat)

	if empty(a:list)
		if mode ==# "b"
			let bufs = getbufinfo({ 'buflisted': 1 })
		elseif mode ==# "f"
			" expand() - handle ~, ~luser, %:h/...
			let expanded_pat = expand(pat)
			let bufs = glob(s:globpath_for_pattern(expanded_pat), 0, 1)

			let make_uniq = 0
			if expanded_pat !=# pat
				" include buffers stored without '~' expansion
				call extend(bufs, glob(s:globpath_for_pattern(pat), 0, 1))
				let make_uniq = 1
			endif

			call sort(bufs)
			if make_uniq
				call uniq(bufs)
			endif

			call map(bufs, { i, name -> { "name": name } })
			"call filter(bufs, { i, name -> s:is_ignored(name) })
		elseif mode ==# "o"
			let bufs = v:oldfiles[:]
			call map(bufs, { i, name -> { "name": name } })
		endif
	else
		let bufs = a:list
	endif

	call filter(bufs, function('s:MatchAndTag', [re, mode]))
	call sort(bufs, 's:Cmp')

	return bufs
endfunction

"function! s:is_ignored(name) abort
"	return 0
"endfunction

function! s:MatchAndTag(pat, mode, i, ent) abort
	let name = a:ent.name
	if empty(name)
		return 0
	endif

	if a:mode ==# "b"
		if a:ent.bufnr is winbufnr(s:preview_winid)
			return 0
		endif
		let name = fnamemodify(name, ":~:.")
	endif

	let a:ent.name = name

	" vim's re isn't the same as perl, and we won't get the shortest match on a
	" line, despite using /.\{-}/
	" e.g.
	" Desktop/abc/package
	"       ^~^~^~~~~^^^^ package
	" instead of
	"             ^^^^^^^ package
	"
	" so, look for shortest:
	let start = -1
	for i in range(strlen(name))
		let [str2, start2, end2] = matchstrpos(name, a:pat, i)
		if start2 is -1
			break
		endif
		let [str, start, end] = [str2, start2, end2]
	endfor

	if start is -1
		return 0
	endif

	let a:ent.matchstr = str
	let a:ent.matchstart = start
	let a:ent.matchend = end
	let a:ent.matchlen = end - start

	return 1
endfunction

function! s:Cmp(a, b) abort
	let a = a:a
	let b = a:b

	let diff = a.matchlen - b.matchlen
	if diff | return diff | endif

	let diff = len(a.matchstr) - len(b.matchstr)
	if diff | return diff | endif

	" could use &wildignore here to compare

	return len(a.name) - len(b.name)
endfunction

function! pinpoint#CompleteBufs(ArgLead, CmdLine, CursorPos) abort
	let bufs = s:MatchingBufs(a:ArgLead, [], "b")
	call map(bufs, { i, ent -> ent.name })
	return bufs
endfunction

function! pinpoint#CompleteFiles(ArgLead, CmdLine, CursorPos) abort
	let bufs = s:MatchingBufs(a:ArgLead, [], "f")
	call map(bufs, { i, ent -> ent.name })
	return bufs
endfunction

function! pinpoint#CompleteOldFiles(ArgLead, CmdLine, CursorPos) abort
	let bufs = s:MatchingBufs(a:ArgLead, [], "o")
	call map(bufs, { i, ent -> ent.name })
	return bufs
endfunction

function! pinpoint#CompletePin(ArgLead, CmdLine, CursorPos) abort
	let [mode, arglead] = s:resolve_mode('p', a:ArgLead)
	let bufs = s:MatchingBufs(arglead, [], mode)
	call map(bufs, { i, ent -> ent.name })
	return bufs
endfunction

" the command given to BufEdit must accept "!" appendin to it
function! pinpoint#Edit(glob, editcmd, bangstr, mods, mode) abort
	let [mode, glob] = s:resolve_mode(a:mode, a:glob)

	let ents = s:MatchingBufs(glob, [], mode)
	if len(ents) < 1
		echoerr "No matches for" glob
		return
	endif

	" just pick the first to match the preview
	if mode ==# "b"
		let path = ents[0].bufnr
	elseif mode ==# "f"
		let path = ents[0].name
	elseif mode ==# "o"
		let path = ents[0].name
	else
		echoerr "Invalid mode" mode
	endif

	execute a:mods a:editcmd a:bangstr path
endfunction

function! pinpoint#EditPreview() abort
	if getcmdtype() != ":" || !empty(getcmdwintype())
		return
	endif

	let matches = s:CmdlineMatchArg()
	if empty(matches)
		call pinpoint#EditPreviewClose()
	else
		call s:BufEditPreviewQueue(matches)
	endif
endfunction

function! s:CmdlineMatchArg() abort
	let matches = cmdline#matching(g:pinpoint_cmds . '\s+([^|]*)$')

	if empty(matches)
		return ''
	endif

	" cmd, arg
	return matches[1:2]
endfunction

function! s:BufEditPreviewQueue(cmd_and_arg) abort
	if g:pinpoint_preview_delay is 0
		call s:BufEditPreviewShow(a:cmd_and_arg)
	else
		" queue up to display after editing
		if s:timer isnot -1
			call timer_stop(s:timer)
		endif
		let s:timer = timer_start(g:pinpoint_preview_delay, function('s:BufEditPreviewShow'))
	endif
endfunction

function! s:ModeStr(mode)
	if a:mode ==# "b"
		return "buffer"
	elseif a:mode ==# "f"
		return "file"
	elseif a:mode ==# "o"
		return "oldfile"
	endif
	return "<unknown mode " .. a:mode .. ">"
endfunction

function! s:ModeFromCmd(cmd)
	return a:cmd[0] ==# "B"
	\  ? "b"
	\  : a:cmd[0] ==# "O"
	\  ? "o"
	\  : a:cmd[0] ==# "F"
	\  ? "f"
	\  : "p"
endfunction

function! s:BufEditPreviewShow(arg_or_timerid) abort
	let cmd_and_arg = a:arg_or_timerid
	if type(cmd_and_arg) is v:t_number
		" called from timer
		let s:timer = -1
		let cmd_and_arg = s:CmdlineMatchArg()
		if empty(cmd_and_arg)
			call pinpoint#EditPreviewClose()
			return
		endif
	endif

	if len(cmd_and_arg) != 2
		return
	endif
	let [cmd, arg] = cmd_and_arg
	if empty(arg)
		call pinpoint#EditPreviewClose()
		return
	endif
	let mode = s:ModeFromCmd(cmd)
	let [mode, cmd] = s:resolve_mode(mode, cmd)

	if !win_id2win(s:preview_winid)
		call s:BufEditPreviewOpen()
	endif

	" Optimisation: since we're not regex, we can detect when the search pattern
	" has just been added to, and keep narrowing down an existing list, instead
	" of starting from getbufinfo() each time
	if len(arg) < len(s:current_ent)
	\ || arg[:len(s:current_ent) - 1] !=# s:current_ent
	\ || (s:slashcount_relevant(mode) && (
	\     s:current_ent_slashcount isnot s:slashcount(arg)
	\     || g:pinpoint_preview_fullwords
	\ ))
		" g:pinpoint_preview_fullwords is checked above to save trying to modify
		" the match logic to also handle fullwords
		let s:current_list = []
		let s:current_ent_slashcount = s:slashcount(arg)
	endif
	let matches = s:MatchingBufs(arg, s:current_list, mode)
	let s:current_ent = arg
	let s:current_list = matches

	let buf = winbufnr(s:preview_winid)
	call setbufline(buf, 1, s:ModeStr(mode) . " preview for '" . arg . "'" . (s:showre ? " /" . s:GetRe(arg) . "/" : ""))

	let saved_win_id = win_getid()
	" goto the preview window for matchaddpos()
	if !win_gotoid(s:preview_winid)
		return
	endif

	call clearmatches()
	for i in range(s:preview_height() - 1)
		let details = ""

		if i >= len(matches)
			let line = ""
			let m = 0
		else
			let m = matches[i]
			let line = m.name . (isdirectory(m.name) ? '/' : '')

			if !g:pinpoint_preview_colour
				let details =
							\ repeat(" ", m.matchstart) .
							\ "^" .
							\ repeat("~", m.matchlen - 1)
			endif
		endif

		if g:pinpoint_preview_colour
			let linenr = i + 2
			call setbufline(buf, linenr, line)
			if type(m) isnot v:t_number && m.matchlen > 0
				call matchaddpos('BufEditMatch', [
				\   [linenr, m.matchstart + 1, m.matchlen]
				\ ])
				" , v:null, -1, { 'window': s:preview_winid })
				" ^ this seems to expose a window redrawing bug in vim
			endif
		else
			call setbufline(buf, i * 2 + 2, line)
			call setbufline(buf, i * 2 + 2 + 1, details)
		endif

		let i += 1
	endfor

	call win_gotoid(saved_win_id)

	redraw
endfunction

function! s:BufEditPreviewOpen() abort
	" affect the 7new below - we don't want an empty NonText line
	let s:saved_laststatus = &laststatus
	let s:restore_win_layout = winrestcmd()
	set laststatus=0
	set modifiable noreadonly
	execute 'botright' s:preview_height() 'new'
	let s:preview_winid = win_getid()
	set winfixheight buftype=nofile bufhidden=wipe

	wincmd p
endfunction

function! s:preview_height() abort
	return &cmdwinheight
endfunction

function! pinpoint#EditPreviewClose() abort
	if s:timer isnot -1
		call timer_stop(s:timer)
		let s:timer = -1
	endif

	let s:current_list = []
	let s:current_ent_slashcount = -1

	if s:preview_winid is -1
		return
	endif
	" could win_gotoid() + q or win_execute(..., "q")
	" but the user can't really switch tabs while this is going on
	let win = win_id2win(s:preview_winid)
	let s:preview_winid = -1
	if !win
		return
	endif

	execute win "q"
	let &laststatus = s:saved_laststatus
	execute s:restore_win_layout
	redraw
endfunction
