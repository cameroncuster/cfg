" custom (golfed)
set wildmenu
filetype indent on
set aw ai is ts=2 sw=2 nu noeb ru cul cindent cino=j1,(0,ws,Ws
sy on   |   im kj <esc>
colorscheme default

" show tabs and trailing spaces
set listchars=tab:\|\ ,trail:_ list

" template buffer
autocmd BufNewFile *.cpp -r ~/programming_team_code/library/contest/template.cpp

" <F5> fast compile
autocmd filetype cpp noremap <F5> :w!<CR>:<C-u>!g++ -std=c++20 %:r.cpp && cat > in && ./a.out < in && rm a.out in<CR>

" <F6> debug compile
autocmd filetype cpp noremap <F6> :w!<CR>:<C-u>!g++ -std=c++20 -Wall -Wextra -pedantic -O2 -Wshadow -Wformat=2 -Wfloat-equal -Wconversion -Wlogical-op -Wshift-overflow=2 -Wduplicated-cond -Wcast-qual -Wcast-align -D_GLIBCXX_DEBUG -D_GLIBCXX_DEBUG_PEDANTIC -D_FORTIFY_SOURCE=2 -fsanitize=undefined -fno-sanitize-recover -fstack-protector %:r.cpp && cat > in && ./a.out < in && rm a.out in<CR>

" <F7> debug compile and debug with GDB
autocmd filetype cpp noremap <F7> :w!<CR>:<C-u>!g++ -g -std=c++20 -Wall -Wextra -pedantic -Wshadow -Wformat=2 -Wfloat-equal -Wconversion -Wlogical-op -Wshift-overflow=2 -Wduplicated-cond -Wcast-qual -Wcast-align -D_GLIBCXX_DEBUG -D_GLIBCXX_DEBUG_PEDANTIC -fsanitize=undefined -fno-sanitize-recover -fstack-protector %:r.cpp && cat > in && gdb -q -ex 'set args < in' a.out && rm a.out in<CR>

" <F8> check spelling
map <F8> :setlocal spell! spelllang=en_us<CR>
