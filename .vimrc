" Excellent HTML formatted copy of the VIm documentation at
" http://vimdoc.sourceforge.net/htmldoc/

set verbose=0

colorscheme freya
set background=dark

filetype plugin indent on
syntax on

set   number
set nocompatible

helptags ~/.vim/doc

set statusline=%02n%M%R%H%W%Y\ [%03b:%02B][%02l/%02L\ %p%%][%c%V]\ %{getcwd()}\ %f

" Forget to sudo to edit a file? Use w!!
" via http://stackoverflow.com/questions/95072/what-are-your-favorite-vim-tricks/96492#96492
cmap w!! %!sudo tee > /dev/null %

" Automatically reload this file when it's saved.
if !exists( "autoload_vimrc" )

  let autoload_vimrc = 1
  autocmd BufWritePost ~/.vimrc source ~/.vimrc

endif

" Sort visually selected text by word
" c d a f e => a c d e f
" http://stackoverflow.com/questions/1327978/sorting-words-not-lines-in-vim
vnoremap <F2> d:execute 'normal i' . join(sort(split(getreg('"'))), '')<CR>"'))))'

" Add blank lines without going into insert mode
" http://stackoverflow.com/questions/3170348/insert-empty-lines-without-entering-insert-mode
map <Leader>O :<C-U>call insert(line("."), repeat([''], v:count1))<CR>
map <Leader>o :<C-U>call append(line("."), repeat([''], v:count1))<CR>

" ScrollColors - colorscheme scroller, chooser and browser
" http://www.vim.org/scripts/script.php?script_id=1488
map <silent><Leader>nc :NEXTCOLOR<CR>
map <silent><Leader>pc :PREVCOLOR<CR>

" CSApprox - Make gvim-only colorschemes work transparently in terminal vim
" http://www.vim.org/scripts/script.php?script_id=2390
set t_Co=256

" Plugins
"
" Align      http://www.vim.org/scripts/script.php?script_id=294
"            http://github.com/vim-scripts/Align
"
" AutoAlign  http://www.vim.org/scripts/script.php?script_id=884
"            http://github.com/vim-scripts/AutoAlign
"
" Surround   http://www.vim.org/scripts/script.php?script_id=1697
"            http://github.com/tpope/vim-surround
"
" ShowMarks  http://www.vim.org/scripts/script.php?script_id=152
"            http://github.com/vim-scripts/showmarks
"
" Syntastic  http://www.vim.org/scripts/script.php?script_id=2736
"            http://github.com/scrooloose/syntastic/
"
" VCSCommand http://www.vim.org/scripts/script.php?script_id=90
"            http://repo.or.cz/w/vcscommand.git

" Need to compare
"
" AutoClose
"   http://www.vim.org/scripts/script.php?script_id=1849 http://github.com/vim-scripts/Autoclose
"   http://www.vim.org/scripts/script.php?script_id=2009 http://github.com/vim-scripts/AutoClose--Alves

" Check these plugins out
"
" Repeat http://www.vim.org/scripts/script.php?script_id=2136
"        http://github.com/tpope/vim-repeat
"
" TVO    http://www.vim.org/scripts/script.php?script_id=517
"        http://github.com/vim-scripts/TVO--The-Vim-Outliner
"        
"        http://github.com/vim-scripts/vimoutliner-colorscheme-fix

" Rip off code from these projects for my own use
"
" Timestamp
" http://github.com/vim-scripts/timestamp
" http://github.com/vim-scripts/timestamp.vim
"
" Whitespace
" http://github.com/vim-scripts/trailing-whitespace.vim
"
