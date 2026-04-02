" Vim startup ASCII art display
" Shows random ASCII art message on startup (no file args only)

" Load generated ASCII art data
source ~/.vim/startup/ascii_art_data.vim

" Available colors for random selection
let s:colors = ['Red', 'Yellow', 'Green', 'Cyan', 'Blue', 'Magenta']

function! s:ShowAsciiArt()
  " Only show when no file arguments
  if argc() > 0
    return
  endif

  " Pick random art and color
  let l:idx = rand() % len(g:ascii_arts)
  let l:art = g:ascii_arts[l:idx]
  let l:color = s:colors[rand() % len(s:colors)]

  " Create scratch buffer
  enew
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted
  setlocal nonumber norelativenumber nocursorline nocursorcolumn
  setlocal signcolumn=no

  " Set highlight
  execute 'highlight StartupArt ctermfg=' . l:color . ' guifg=' . l:color

  " Calculate vertical centering
  let l:win_height = winheight(0)
  let l:art_height = len(l:art)
  let l:pad_top = max([(l:win_height - l:art_height) / 2, 0])

  " Calculate horizontal centering
  let l:win_width = winwidth(0)
  let l:max_art_width = 0
  for l:line in l:art
    let l:w = strdisplaywidth(l:line)
    if l:w > l:max_art_width
      let l:max_art_width = l:w
    endif
  endfor
  let l:pad_left = max([(l:win_width - l:max_art_width) / 2, 0])
  let l:prefix = repeat(' ', l:pad_left)

  " Build buffer lines
  let l:lines = repeat([''], l:pad_top)
  for l:line in l:art
    call add(l:lines, l:prefix . l:line)
  endfor

  " Fill buffer
  call setline(1, l:lines)
  setlocal nomodifiable

  " Apply syntax highlighting to art lines
  for l:i in range(l:pad_top + 1, l:pad_top + l:art_height)
    call matchaddpos('StartupArt', [l:i])
  endfor

  " Close on any key
  nnoremap <buffer><silent> q :enew<CR>
  nnoremap <buffer><silent> <CR> :enew<CR>
  nnoremap <buffer><silent> i :enew<CR>
  nnoremap <buffer><silent> <Space> :enew<CR>
endfunction

autocmd VimEnter * ++nested call s:ShowAsciiArt()
