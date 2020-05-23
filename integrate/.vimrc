colorscheme desert

" Make sure documentation is up to date
" If docs are ever added to ~/.vim/doc, uncomment this line.
"helptags ~/.vim/doc

set nocompatible

" Recommended by pathogen author:
"
" Vim sessions default to capturing all global options, which includes the
" `'runtimepath'` that pathogen.vim manipulates.  This can cause other
" problems too, so I recommend turning that behavior off.

set sessionoptions-=options

"let g:pathogen_disable=[ 'showmarks' ]

runtime bundle/pathogen/autoload/pathogen.vim
execute pathogen#infect('bundle/{}', '$HOME/.vim.d/{}', '$PRJHOME/.vim.d')
execute pathogen#helptags()

filetype plugin indent on
syntax on
