function! s:CompleteOldFilesMatch(ArgLead, CmdLine, CursorPos) abort
	let pat = glob2regpat("*" . a:ArgLead . "*")

	let list = v:oldfiles[:]
	call filter(list, { i, ent -> match(ent, pat) >= 0 })

	return list
endfunction

function! pinpoint#oldfiles#CompleteOldFilesMatch(...)
	return call('s:CompleteOldFilesMatch', a:000)
endfunction

function! pinpoint#oldfiles#OldEdit(glob, editcmd, mods) abort
	let glob = a:glob

	if filereadable(glob)
		let path = glob
	else
		let ents = s:CompleteOldFilesMatch(glob, glob, 0)
		if len(ents) > 1
			echoerr "Too many matches for" glob
			return
		elseif len(ents) < 1
			echoerr "No matches for" glob
			return
		endif

		let path = ents[0]
	endif

	execute a:mods a:editcmd path
endfunction
