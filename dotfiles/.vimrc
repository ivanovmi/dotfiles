set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" PLUGINS SECTION!
" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

Plugin 'tpope/vim-fugitive'
Plugin 'nvie/vim-flake8'
Plugin 'tmhedberg/SimpylFold'
Plugin 'kien/ctrlp.vim'
Plugin 'ludovicchabant/vim-lawrencium'
Plugin 'davidhalter/jedi-vim'
" Syntax check
Plugin 'vim-syntastic/syntastic'
" Color schemes
Plugin 'flazz/vim-colorschemes'
" NerdTree
Plugin 'scrooloose/nerdtree'
" Status bar
"Plugin 'Lokaltog/powerline'
"Plugin 'vim-airline/vim-airline'
"Plugin 'vim-airline/vim-airline-themes'
Plugin 'scrooloose/nerdcommenter'

Plugin 'nvie/vim-togglemouse'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line
filetype plugin indent on     " required!
syntax on
set hlsearch
set number
highlight LineNr term=bold cterm=NONE ctermfg=DarkGrey ctermbg=NONE gui=NONE guifg=DarkGrey guibg=NONE

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_mode_map = { 'mode': 'active',
                           \  'active_filetypes': ['python', 'c', 'js', 'ruby'],
                           \ 'passive_filetypes': ['html'] }
let g:syntastic_python_checkers = ['pep8', 'flake8']
let g:syntastic_ruby_checkers = ['rubocop']
let g:syntastic_c_checkers = ['gcc', 'make', 'ycm']
let g:syntastic_c_compiler_options = '-Wall'
let g:syntastic_cpp_compiler_options = '-std=gnu++14'
let g:syntastic_cpp_check_header = 1
let g:syntastic_cpp_auto_refresh_includes = 1
let g:syntastic_javascript_checkers = ['eslint']
let g:syntastic_rst_checkers = ['rstcheck']
let g:syntastic_aggregate_errors = 1
let g:syntastic_enable_balloons = 1
let g:syntastic_ignore_files = ['\m^/usr/local/', '\m\c\/.tox/']

" jedi-vim
let g:jedi#auto_initialization = 1
let g:jedi#auto_vim_configuration = 0
let g:jedi#popup_on_dot = 1
let g:jedi#popup_select_first = 0
let g:jedi#completions_enabled = 0
let g:jedi#completions_command = ""
let g:jedi#show_call_signatures = 0
let g:jedi#goto_assignments_command = "<leader>da"
let g:jedi#goto_definitions_command = "<leader>dd"
let g:jedi#documentation_command = "<leader>dk"
let g:jedi#usages_command = "<leader>du"
let g:jedi#rename_command = "<leader>dr"
let g:jedi#use_splits_not_buffers = "right"
let g:jedi#use_tabs_not_buffers = 0
autocmd FileType python setlocal completeopt-=preview

" nerdtree
nmap <C-n> :NERDTreeToggle<CR>

" Remove Trailing Whitespaces
command! RTW :%s/\s\+$//e

" highlight 79th character where sensible.
autocmd BufEnter *.py call matchadd('ColorColumn', '\%79v', 100)
autocmd BufEnter *.rst call matchadd('ColorColumn', '\%79v', 100)

" set W to be 'sudo w'
command! W :execute ':silent w !sudo tee % > /dev/null' | :edit!

" Wq is ok
command! Wq wq

" Send more characters for redraws
set ttyfast
"
" " Enable mouse use in all modes
set mouse=a
"
" " Set this to the name of your terminal that supports mouse codes.
" " Must be one of: xterm, xterm2, netterm, dec, jsbterm, pterm
set ttymouse=xterm2


"let g:airline_theme = 'molokai'
let g:airline_powerline_fonts = 1
set laststatus=2
