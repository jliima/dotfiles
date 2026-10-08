" Themer colorscheme for Vim and Neovim, with the same per-language syntax colors as the other editors (Java, Shell,
" Python, CSS and XML). Not activated automatically: run `:colorscheme themer` to try it, or add that line to your
" init.lua or vimrc.

hi clear
if exists('syntax_on')
  syntax reset
endif
let g:colors_name = 'themer'
set background={{ variant }}

hi Normal       guifg={{ text }} guibg={{ bg }}
hi NonText      guifg={{ text-disabled }} guibg={{ bg }}
hi CursorLine   guibg={{ surface-hover }}
hi CursorLineNr guifg={{ text }} guibg=NONE
hi LineNr       guifg={{ text-faint }}
hi VertSplit    guifg={{ line }} guibg={{ bg }}
hi StatusLine   guifg={{ text }} guibg={{ bg-sunken }}
hi StatusLineNC guifg={{ text-faint }} guibg={{ bg-sunken }}
hi Visual       guibg={{ selection }}
hi Search       guibg={{ surface-active }}
hi IncSearch    guibg={{ accent }} guifg={{ on-accent }}
hi Pmenu        guifg={{ text }} guibg={{ surface-raised }}
hi PmenuSel     guifg={{ on-accent }} guibg={{ accent }}
hi MatchParen   guibg={{ surface-active }}

" Generic syntax groups
hi Comment      guifg={{ syntax-comment }}
hi String       guifg={{ syntax-string }}
hi Character    guifg={{ syntax-string }}
hi Number       guifg={{ syntax-number }}
hi Keyword      guifg={{ syntax-keyword }}
hi Statement    guifg={{ syntax-keyword }}
hi Conditional  guifg={{ syntax-keyword }}
hi Repeat       guifg={{ syntax-keyword }}
hi Function     guifg={{ syntax-function }}
hi Identifier   guifg={{ syntax-variable }}
hi Type         guifg={{ syntax-type }}
hi StorageClass guifg={{ syntax-type }}
hi Structure    guifg={{ syntax-class }}
hi Constant     guifg={{ syntax-constant }}
hi Operator     guifg={{ syntax-operator }}
hi PreProc      guifg={{ syntax-annotation }}
hi Special      guifg={{ syntax-escape }}
hi SpecialChar  guifg={{ syntax-escape }}
hi Delimiter    guifg={{ syntax-punctuation }}
hi Todo         guifg={{ syntax-doc-tag }}
hi Error        guifg={{ danger }}
hi Warning      guifg={{ warning }}

" Per-language groups where a language reads its tokens differently from the generic ones
augroup themer_lang_syntax
  autocmd!

  autocmd FileType java hi StorageClass guifg={{ syntax-keyword }}
        \ | hi PreProc      guifg={{ syntax-annotation }}
        \ | hi SpecialChar  guifg={{ syntax-escape }}
        \ | hi Todo         guifg={{ syntax-doc-tag }}
        \ | hi Structure    guifg={{ syntax-class }}

  autocmd FileType sh,bash hi Function guifg={{ syntax-function }}
        \ | hi Identifier   guifg={{ syntax-property }}

  autocmd FileType python hi PreProc guifg={{ syntax-annotation }}
        \ | hi Special      guifg={{ syntax-type }}
        \ | hi Structure    guifg={{ syntax-class }}

  autocmd FileType css,scss,less hi Identifier guifg={{ syntax-tag }}
        \ | hi Type         guifg={{ syntax-property }}
        \ | hi Constant     guifg={{ syntax-variable }}
        \ | hi PreProc      guifg={{ syntax-attribute }}
        \ | hi Number       guifg={{ syntax-constant }}
        \ | hi Special      guifg={{ syntax-doc-tag }}
        \ | hi Statement    guifg={{ syntax-annotation }}
        \ | hi String       guifg={{ syntax-string }}
        \ | hi Delimiter    guifg={{ syntax-punctuation }}

  autocmd FileType xml,html hi Statement guifg={{ syntax-tag }}
        \ | hi Delimiter    guifg={{ syntax-punctuation }}
        \ | hi Type         guifg={{ syntax-attribute }}
        \ | hi String       guifg={{ syntax-string }}
        \ | hi Special      guifg={{ syntax-escape }}
        \ | hi Identifier   guifg={{ syntax-type }}
augroup END
