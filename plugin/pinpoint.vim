if !exists('g:pinpoint_preview_delay')
	let g:pinpoint_preview_delay = 0
endif
if !exists('g:pinpoint_preview_colour')
	let g:pinpoint_preview_colour = 1
endif
if !exists('g:pinpoint_preview_fullwords')
	let g:pinpoint_preview_fullwords = 0
endif

command! -complete=customlist,pinpoint#oldfiles#CompleteOldFilesMatch -nargs=1 Oldedit   call pinpoint#oldfiles#OldEdit(<q-args>, "edit", <q-mods>)
command! -complete=customlist,pinpoint#oldfiles#CompleteOldFilesMatch -nargs=1 Oldsplit  call pinpoint#oldfiles#OldEdit(<q-args>, "split", <q-mods>)
command! -complete=customlist,pinpoint#oldfiles#CompleteOldFilesMatch -nargs=1 Oldvsplit call pinpoint#oldfiles#OldEdit(<q-args>, "vsplit", <q-mods>)

let g:pinpoint_cmds = '(Buf|F)%(%[edit]|%[vsplit]|%[split]|%[tabedit])'
"                ^~~~~~~ capture used

command! -bang -bar -complete=customlist,pinpoint#CompleteBufs -nargs=1 Bufedit    call pinpoint#BufEdit(<q-args>, "buffer", <q-bang>, <q-mods>, "b")
command! -bang -bar -complete=customlist,pinpoint#CompleteBufs -nargs=1 Bufsplit   call pinpoint#BufEdit(<q-args>, "sbuffer", <q-bang>, <q-mods>, "b")
command! -bang -bar -complete=customlist,pinpoint#CompleteBufs -nargs=1 Bufvsplit  call pinpoint#BufEdit(<q-args>, "vert sbuffer", <q-bang>, <q-mods>, "b")
command! -bang -bar -complete=customlist,pinpoint#CompleteBufs -nargs=1 Buftabedit call pinpoint#BufEdit(<q-args>, "tabedit | buffer", <q-bang>, <q-mods>, "b")
" -range -addr=tabs

command! -bang -bar -complete=customlist,pinpoint#CompleteFiles -nargs=1 Fedit    call pinpoint#BufEdit(<q-args>, "edit", <q-bang>, <q-mods>, "f")
command! -bang -bar -complete=customlist,pinpoint#CompleteFiles -nargs=1 Fsplit   call pinpoint#BufEdit(<q-args>, "split", <q-bang>, <q-mods>, "f")
command! -bang -bar -complete=customlist,pinpoint#CompleteFiles -nargs=1 Fvsplit  call pinpoint#BufEdit(<q-args>, "vsplit", <q-bang>, <q-mods>, "f")
command! -bang -bar -complete=customlist,pinpoint#CompleteFiles -nargs=1 Ftabedit call pinpoint#BufEdit(<q-args>, "tabedit", <q-bang>, <q-mods>, "f")

augroup BufEdit
	autocmd!

	autocmd CmdlineChanged * call pinpoint#BufEditPreview()
	autocmd CmdlineLeave * call pinpoint#BufEditPreviewClose()
augroup END

highlight BufEditMatch ctermfg=blue
