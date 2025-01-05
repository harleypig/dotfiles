" I don't need the -i, apparently my aliases are being loaded now.
"set   shellcmdflag=-ic

"===========================================================================================
" Refactor starts here


" Movement

set   whichwrap=b,s,<,>,[,] " list of flags specifying which commands wrap to another line
set noautochdir             " change to directory of file in buffer
set   wrapscan              " search commands wrap around the end of the buffer
set   incsearch             " show match for partly typed search command
set   magic                 " change the way backslashes are used in search patterns
set   ignorecase            " ignore case when using a search pattern
set   smartcase             " override 'ignorecase' when pattern has upper case characters

" Display

set   scroll=11 " number of lines to scroll for CTRL-U and CTRL-D
set   scrolloff=999999 " number of screen lines to show around the cursor
set   wrap  " long lines wrap
set   linebreak  " wrap long lines at a character in 'breakat'
set   display=uhex,lastline " include "lastline" to show the last line even if it doesn't fit
set   foldlevelstart=99 " start editing with all folds opened
set   concealcursor=nc
