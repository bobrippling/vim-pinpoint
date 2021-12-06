if !exists('g:pinpoint_preview_delay')
	let g:pinpoint_preview_delay = 0
endif
if !exists('g:pinpoint_preview_colour')
	let g:pinpoint_preview_colour = 1
endif
if !exists('g:pinpoint_preview_fullwords')
	let g:pinpoint_preview_fullwords = 0
endif

let g:pinpoint_cmds = '(Buf|F|Old)%(%[edit]|%[vsplit]|%[split]|%[tabedit])'
"                       ^~~~~~~~~ capture used

command! -nargs=1 -complete=customlist,pinpoint#CompleteOldFiles Oldedit    call pinpoint#Edit(<q-args>, "edit", <q-bang>, <q-mods>, "o")
command! -nargs=1 -complete=customlist,pinpoint#CompleteOldFiles Oldsplit   call pinpoint#Edit(<q-args>, "split", <q-bang>, <q-mods>, "o")
command! -nargs=1 -complete=customlist,pinpoint#CompleteOldFiles Oldvsplit  call pinpoint#Edit(<q-args>, "vsplit", <q-bang>, <q-mods>, "o")
command! -nargs=1 -complete=customlist,pinpoint#CompleteOldFiles Oldtabedit call pinpoint#Edit(<q-args>, "tabedit", <q-bang>, <q-mods>, "o")

command! -nargs=1 -bang -bar -complete=customlist,pinpoint#CompleteBufs Bufedit    call pinpoint#Edit(<q-args>, "buffer", <q-bang>, <q-mods>, "b")
command! -nargs=1 -bang -bar -complete=customlist,pinpoint#CompleteBufs Bufsplit   call pinpoint#Edit(<q-args>, "sbuffer", <q-bang>, <q-mods>, "b")
command! -nargs=1 -bang -bar -complete=customlist,pinpoint#CompleteBufs Bufvsplit  call pinpoint#Edit(<q-args>, "vert sbuffer", <q-bang>, <q-mods>, "b")
command! -nargs=1 -bang -bar -complete=customlist,pinpoint#CompleteBufs Buftabedit call pinpoint#Edit(<q-args>, "tabedit | buffer", <q-bang>, <q-mods>, "b")

command! -nargs=1 -bang -bar -complete=customlist,pinpoint#CompleteFiles Fedit    call pinpoint#Edit(<q-args>, "edit", <q-bang>, <q-mods>, "f")
command! -nargs=1 -bang -bar -complete=customlist,pinpoint#CompleteFiles Fsplit   call pinpoint#Edit(<q-args>, "split", <q-bang>, <q-mods>, "f")
command! -nargs=1 -bang -bar -complete=customlist,pinpoint#CompleteFiles Fvsplit  call pinpoint#Edit(<q-args>, "vsplit", <q-bang>, <q-mods>, "f")
command! -nargs=1 -bang -bar -complete=customlist,pinpoint#CompleteFiles Ftabedit call pinpoint#Edit(<q-args>, "tabedit", <q-bang>, <q-mods>, "f")

augroup BufEdit
	autocmd!

	autocmd CmdlineChanged * call pinpoint#EditPreview()
	autocmd CmdlineLeave * call pinpoint#EditPreviewClose()
augroup END

highlight BufEditMatch ctermfg=blue
