if !exists('g:pinpoint_preview_delay')
	let g:pinpoint_preview_delay = 0
endif
if !exists('g:pinpoint_preview_colour')
	let g:pinpoint_preview_colour = 1
endif
if !exists('g:pinpoint_preview_fullwords')
	let g:pinpoint_preview_fullwords = 0
endif
if !exists('g:pinpoint_fuzzy')
	let g:pinpoint_fuzzy = exists("*matchfuzzy")
endif

let g:pinpoint_cmds = '\C(Buf|F|Old)%(e%[dit]|v%[split]|s%[plit]|t%[abedit])'
"                       ^~~~~~~~~ capture used

command! -bar -nargs=1 -complete=customlist,pinpoint#CompleteOldFiles Oldedit    call pinpoint#Edit(<q-args>, "edit", <q-bang>, <q-mods>, "o")
command! -bar -nargs=1 -complete=customlist,pinpoint#CompleteOldFiles Oldsplit   call pinpoint#Edit(<q-args>, "split", <q-bang>, <q-mods>, "o")
command! -bar -nargs=1 -complete=customlist,pinpoint#CompleteOldFiles Oldvsplit  call pinpoint#Edit(<q-args>, "vsplit", <q-bang>, <q-mods>, "o")
if has('nvim')
	command! -bar -nargs=1 -complete=customlist,pinpoint#CompleteOldFiles -count=+1 -addr=tabs Oldtabedit call pinpoint#Edit(<q-args>, <q-count> . "tabedit", <q-bang>, <q-mods>, "o")
else
	command! -bar -nargs=1 -complete=customlist,pinpoint#CompleteOldFiles -count=1  -addr=tabs Oldtabedit call pinpoint#Edit(<q-args>, <q-count> . "tabedit", <q-bang>, <q-mods>, "o")
endif

command! -nargs=1 -bang -bar -complete=customlist,pinpoint#CompleteBufs Bufedit    call pinpoint#Edit(<q-args>, "buffer", <q-bang>, <q-mods>, "b")
command! -nargs=1 -bang -bar -complete=customlist,pinpoint#CompleteBufs Bufsplit   call pinpoint#Edit(<q-args>, "sbuffer", <q-bang>, <q-mods>, "b")
command! -nargs=1 -bang -bar -complete=customlist,pinpoint#CompleteBufs Bufvsplit  call pinpoint#Edit(<q-args>, "vert sbuffer", <q-bang>, <q-mods>, "b")
if has('nvim')
	command! -nargs=1 -bang -bar -complete=customlist,pinpoint#CompleteBufs -count=+1 -addr=tabs Buftabedit call pinpoint#Edit(<q-args>, <q-count> . "tabedit | buffer", <q-bang>, <q-mods>, "b")
else
	command! -nargs=1 -bang -bar -complete=customlist,pinpoint#CompleteBufs -count=1  -addr=tabs Buftabedit call pinpoint#Edit(<q-args>, <q-count> . "tabedit | buffer", <q-bang>, <q-mods>, "b")
endif

command! -nargs=1 -bang -bar -complete=customlist,pinpoint#CompleteFiles Fedit    call pinpoint#Edit(<q-args>, "edit", <q-bang>, <q-mods>, "f")
command! -nargs=1 -bang -bar -complete=customlist,pinpoint#CompleteFiles Fsplit   call pinpoint#Edit(<q-args>, "split", <q-bang>, <q-mods>, "f")
command! -nargs=1 -bang -bar -complete=customlist,pinpoint#CompleteFiles Fvsplit  call pinpoint#Edit(<q-args>, "vsplit", <q-bang>, <q-mods>, "f")
if has('nvim')
	command! -nargs=1 -bang -bar -complete=customlist,pinpoint#CompleteFiles -count=+1 -addr=tabs Ftabedit call pinpoint#Edit(<q-args>, <q-count> . "tabedit", <q-bang>, <q-mods>, "f")
else
	command! -nargs=1 -bang -bar -complete=customlist,pinpoint#CompleteFiles -count=1  -addr=tabs Ftabedit call pinpoint#Edit(<q-args>, <q-count> . "tabedit", <q-bang>, <q-mods>, "f")
endif

nnoremap <expr> <C-p> <SID>init(0)
nnoremap <expr> <M-p> <SID>init(1)

function! s:init(buf)
	if a:buf
		let cmd = ":\<C-U>Buf"
	else
		let cmd = ":\<C-U>F"
	endif

	if &modified
		" split the window if curbuf is +
		let cmd .= "s"
	else
		let cmd .= "e"
	endif

	return cmd . " "
endfunction

cnoremap <expr> <Plug>(pinpoint-upgradecmdline) pinpoint#UpgradeEditCmdlineExpr()

augroup BufEdit
	autocmd!

	autocmd CmdlineChanged * call pinpoint#EditPreview()
	autocmd CmdlineLeave * call pinpoint#EditPreviewClose()
augroup END

highlight BufEditMatch ctermfg=blue
