execute pathogen#infect()
syntax on
filetype plugin indent on

" type \rt to recreate ctags (typically after adding a file/type/method)
map <Leader>rt :!ctags --tag-relative=yes --extras=+f -Rf.git/tags --exclude=.git --exclude=pkg --exclude=node_modules --languages=-sql<CR><CR>
"" store ctags inside untracked git folder
set tags+=.git/tags

set expandtab
set shiftwidth=2
set softtabstop=2

set ruler
set laststatus=2
set scrolloff=2

set nocompatible
set backspace=indent,eol,start
set autoindent		" always set autoindenting on
set history=50		" keep 50 lines of command line history
set showcmd		" display incomplete commands
set incsearch		" do incremental searching
set relativenumber
set suffixesadd=.rb
set path+=lib/**,test/**
let g:ruby_path = &path

" from https://github.com/tpope/gem-ctags
autocmd FileType ruby let &l:tags = pathogen#legacyjoin(pathogen#uniq(
      \ pathogen#split(&tags) +
      \ map(split($GEM_PATH,':'),'v:val."/gems/*/tags"')))


" non-cargo-cult
set directory=$HOME/.vim/swapfiles//
autocmd BufWritePre * :%s/\s\+$//e " trim trailing whitespace on save. YOLO!
autocmd BufLeave,FocusLost * silent! wall " auto-save on blur. YOLO!
set autoread " automatically reload when files change because YOLO!
if $TMUX == ''
  set clipboard+=unnamed " share the macOS pasteboard instead of a Vim register
endif
set guifont=Source\ Code\ Pro:h22
autocmd! GUIEnter * set vb t_vb= " disable audible bell in macvim
set visualbell t_vb= " disable audible bell in terminal

" Airline
let g:airline_theme='light'

" Lint with ale + standardrb
let g:ale_linters = { 'ruby': ['standardrb'], 'javascript': ['standard']  }
let g:ale_fix_on_save = 1
let g:ale_fixers = { 'ruby': ['standardrb'], 'javascript': ['standard'] }


" Airline + Ale
let g:airline#extensions#ale#enabled = 1


" use ripgrep for grep
set grepprg=rg\ --vimgrep

function DoubleMap(bind, command, return_to_insert)
  exec "nmap " . a:bind . " " . a:command
  if a:return_to_insert
    exec "imap " . a:bind . " <ESC>" . a:command . "i"
  else
    exec "imap " . a:bind . " <ESC>" . a:command
  endif
endfunction
" use ctrl-p for fzf tab split
nnoremap <silent> <C-p> :Files<CR>
imap <C-x><C-l> <plug>(fzf-complete-line)
" use \tt to open a new tab from the fzf dialog
nnoremap <leader>tt :tabnew<CR>:Files<CR>
" use \dd to run Dispatch (usually a solo test file)
nnoremap <leader>dd :w!<CR>:Dispatch<CR>
" use ctrl-w to save and dispatch
" nnoremap <C-W> :w<CR>:Dispatch<CR>

" use ctrl-a to save all and then be in normal mod
call DoubleMap("<C-A>", ":wa<CR>", 0)

" use ctrl-1 to tab back
call DoubleMap("<C-W>", ":tabprevious<CR>", 0)
" use ctrl-2 to tab ahead
call DoubleMap("<C-E>", ":tabnext<CR>", 0)
" use ctrl-q to quit
call DoubleMap("<C-D>", ":wq<CR>", 0)
" use \qq to format the current paragraph/block to 80c's
nnoremap <leader>qq gqap<CR>
" use \cc to copy the current visual selection
nnoremap <leader>cc :call system('pbcopy', @0)<CR>
" use ctrl-a to switch to alt file
" nnoremap <C-A> :w!<CR>:A<CR>
" open quickfix with \ii
nnoremap <leader>ii :copen<CR>
" close quickfix with \oo
nnoremap <leader>oo :cclose<CR>
" close quickfix with \pry
nnoremap <leader>pry irequire "pry"; binding.pry

" add a Find command using ripgrep
command! -bang -nargs=* Find call fzf#vim#grep('rg --column --line-number --no-heading --fixed-strings --ignore-case --follow --glob "!.git/*" --color "always" '.shellescape(<q-args>), 1, <bang>0)
nnoremap <leader>ff :Find<CR>

" allow project specific vimrcs
set exrc

" enable spellchecking on markdown
autocmd BufRead,BufNewFile *.md setlocal spell
set complete+=kspell

" project-specific but I use it a lot so here goes
set makeprg=rake\ test
compiler rake

" easier 80c's paragraph reformating with gq
au BufRead,BufNewFile *.md setlocal textwidth=80
au BufNewFile,BufRead *.us setlocal ft=html

" easier split navigation with C-JKLH instead of hitting C-W first
set splitbelow
set splitright
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" @tenderlove neckbeard settings
let ruby_space_errors = 1
let c_space_errors = 1
set colorcolumn=81 " show visual indicator of >80c lines

" cargo cult search and align settings
vnoremap <leader>gg y:Ggrep <c-r>"<cr>
command! -nargs=? -range Align <line1>,<line2>call AlignSection('<args>')
vnoremap <silent> <Leader>a :Align<CR>
function! AlignSection(regex) range
  let extra = 1
  let sep = empty(a:regex) ? '=' : a:regex
  let maxpos = 0
  let section = getline(a:firstline, a:lastline)
  for line in section
    let pos = match(line, ' *'.sep)
    if maxpos < pos
      let maxpos = pos
    endif
  endfor
  call map(section, 'AlignLine(v:val, sep, maxpos, extra)')
  call setline(a:firstline, section)
endfunction

function! AlignLine(line, sep, maxpos, extra)
  let m = matchlist(a:line, '\(.\{-}\) \{-}\('.a:sep.'.*\)')
  if empty(m)
    return a:line
  endif
  let spaces = repeat(' ', a:maxpos - strlen(m[1]) + a:extra)
  return m[1] . spaces . m[2]
endfunction
