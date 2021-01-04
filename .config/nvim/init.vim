"
" Plugin section (Plugin manager vim-plug)
"

" Bootstrap if not yet installed
let autoload_plug_path = stdpath('data') . '/site/autoload/plug.vim'
if !filereadable(autoload_plug_path)
  silent execute '!curl -fLo ' . autoload_plug_path . '  --create-dirs 
      \ "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
unlet autoload_plug_path

" Start loading plugins
call plug#begin(stdpath('data') . '/plugged')

" ayu theme for nvim
Plug 'ayu-theme/ayu-vim'

" Stop loading plugins
call plug#end()

"
" Theme Handling
"
set termguicolors
let ayucolor="dark"
colorscheme ayu

"
" Editor Settings
"

set relativenumber
set hlsearch
set textwidth=80
set colorcolumn=80   " indicate column
set nowrap           " do not automatically wrap on load
set formatoptions-=t " do not automatically wrap text when typing
