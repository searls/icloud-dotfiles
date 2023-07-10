execute pathogen#infect()
syntax on
filetype plugin indent on

" I like to live dangerously
set noswapfile

" But not that dangerously
if !isdirectory($HOME."/.vim")
    call mkdir($HOME."/.vim", "", 0770)
endif
if !isdirectory($HOME."/.vim/undo-dir")
    call mkdir($HOME."/.vim/undo-dir", "", 0700)
endif
set undodir=~/.vim/undo-dir
set undofile


" type \rt to recreate ctags (typically after adding a file/type/method)
" disabling in favor of binding \rt to ripper-tags in vscode (which shares this config file oops oh well)
"map <Leader>rt :!ctags --tag-relative=yes --extras=+f -Rf.git/tags --exclude=.git --exclude=pkg --exclude=node_modules --languages=-sql<CR><CR>
"" store ctags inside untracked git folder
" set tags+=.git/tags

set expandtab
set shiftwidth=2
set softtabstop=2
set redrawtime=10000 " LOLLLLLLL large JS files

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
let g:ruby_indent_assignment_style = 'variable'
let g:ruby_indent_hanging_elements = 0

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

" From: https://github.com/flazz/vim-colorschemes
" colorscheme Light

" Lint with ale + standardrb
let g:ale_linters_explicit = 1
let g:ale_linters = { 'ruby': ['standardrb'], 'javascript': ['standard']  }
let g:ale_fix_on_save = 1
let g:ale_fixers = { 'ruby': ['standardrb'], 'javascript': ['standard'] }

" Airline + Ale
let g:airline#extensions#ale#enabled = 1


" use ripgrep for grep
set grepprg=rg\ --vimgrep

" add fzf bindings
set rtp+=/opt/homebrew/opt/fzf

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

call DoubleMap("<Left>", ":tabprevious<CR>", 0)
call DoubleMap("<Right>", ":tabnext<CR>", 0)
" noremap <Up> :m--1 <CR>
" noremap <Down> :m+1 <CR>

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
" type cp in normal mode to copy the current relative file path
nmap cp :let @+ = expand("%")<CR>
" close quickfix with \pry
nnoremap <leader>pry ibinding.irb

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

" vim-pencil, don't let it autoformat b/c it screws up headers
let g:pencil#autoformat = 0

" easier 80c's paragraph reformating with gq
au BufRead,BufNewFile *.md setlocal textwidth=80
au BufNewFile,BufRead *.us setlocal ft=html
set nojoinspaces "<- 1 space after periods

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

" Add this because dealing with a lot of prose that is soft-wrapped is really
" frustrating in vim otherwise
"
" mapping to make movements operate on 1 screen line in wrap mode
"
" source: https://stackoverflow.com/questions/4946421/vim-moving-with-hjkl-in-long-lines-screen-lines
function! ScreenMovement(movement)
   if &wrap
      return "g" . a:movement
   else
      return a:movement
   endif
endfunction
onoremap <silent> <expr> j ScreenMovement("j")
onoremap <silent> <expr> k ScreenMovement("k")
onoremap <silent> <expr> 0 ScreenMovement("0")
onoremap <silent> <expr> ^ ScreenMovement("^")
onoremap <silent> <expr> $ ScreenMovement("$")
nnoremap <silent> <expr> j ScreenMovement("j")
nnoremap <silent> <expr> k ScreenMovement("k")
nnoremap <silent> <expr> 0 ScreenMovement("0")
nnoremap <silent> <expr> ^ ScreenMovement("^")
nnoremap <silent> <expr> $ ScreenMovement("$")

" Prevent dangerous commands from being run in project dotfiles
set secure
