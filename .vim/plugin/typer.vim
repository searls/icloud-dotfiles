let g:typer_speed    = 3
let g:typer_zz_count = 16

function! TyperLoop(file)
	"tabnew
	"let type  = fnamemodify(a:file, ':e')
	"let name  = system('echo $RANDOM')
	"let name  = substitute(name, '\n', '', '')
	"let name  = substitute(name, '\r', '', '')
	"let final = '/tmp/'.name.'.'.type
	"execute ':write '.final
	"execute ':edit  '.final
	"redraw
	let line_count = 0
	for line in readfile(a:file)
		let len = strlen(line)
		let i   = 0
		while i < len
			let c  = strpart(line, i, g:typer_speed)
			let i += g:typer_speed
			call getchar()
			execute "normal! GA".c
			redraw
		endwhile
		execute "normal! Go"
		call cursor(line('.')+1, 1)
		let line_count += 1
		if line_count > g:typer_zz_count
			let line_count = 0
			execute "normal! \zz"
		endif
		redraw
	endfor
	"echo 'Typing has been finished! Press Ctrl+C to exit...'
	while 1
		call getchar()
	endwhile
endfunction

:command! -nargs=1 -complete=file Typer :call TyperLoop('<args>')

