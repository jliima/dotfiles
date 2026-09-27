" Pywal colorscheme for Vim/Neovim, matching IntelliJ's per-language colors
" for Java, Shell, Python, CSS and XML (see parecolors.json's
" syntax<Lang><Category> keys). Not activated automatically: run
" `:colorscheme pywal` to try it, or add that line to your init.lua/vimrc.

hi clear
if exists('syntax_on')
  syntax reset
endif
let g:colors_name = 'pywal'
set background=dark

hi Normal       guifg={foreground} guibg={background}
hi NonText      guifg={textDisabled} guibg={background}
hi CursorLine   guibg={highlight}
hi CursorLineNr guifg={foreground} guibg=NONE
hi LineNr       guifg={textDisabled}
hi VertSplit    guifg={border} guibg={background}
hi StatusLine   guifg={foreground} guibg={backgroundAlt}
hi StatusLineNC guifg={textDisabled} guibg={backgroundAlt}
hi Visual       guibg={selection}
hi Search       guibg={highlightActive}
hi IncSearch    guibg={accent} guifg={textInverse}
hi Pmenu        guifg={foreground} guibg={surface}
hi PmenuSel     guifg={textInverse} guibg={accent}
hi MatchParen   guibg={borderSubtle}

" Generic syntax groups (unchanged: same generic keys other templates use)
hi Comment      guifg={syntaxComment}
hi String       guifg={syntaxString}
hi Character    guifg={syntaxString}
hi Number       guifg={syntaxNumber}
hi Keyword      guifg={syntaxKeyword}
hi Statement    guifg={syntaxKeyword}
hi Conditional  guifg={syntaxKeyword}
hi Repeat       guifg={syntaxKeyword}
hi Function     guifg={syntaxFunction}
hi Identifier   guifg={syntaxVariable}
hi Type         guifg={syntaxType}
hi StorageClass guifg={syntaxType}
hi Structure    guifg={syntaxClass}
hi Constant     guifg={syntaxConstant}
hi Operator     guifg={syntaxOperator}
hi PreProc      guifg={syntaxAnnotation}
hi Special      guifg={syntaxStringEscape}
hi SpecialChar  guifg={syntaxStringEscape}
hi Delimiter    guifg={syntaxPunctuation}
hi Todo         guifg={syntaxDocTag}
hi Error        guifg={error}
hi Warning      guifg={warning}

augroup pywal_lang_syntax
  autocmd!

  autocmd FileType java hi Keyword     guifg={syntaxJavaKeyword}
        \ | hi StorageClass guifg={syntaxJavaModifier}
        \ | hi PreProc      guifg={syntaxJavaAnnotation}
        \ | hi String       guifg={syntaxJavaString}
        \ | hi SpecialChar  guifg={syntaxJavaStringEscape}
        \ | hi Comment      guifg={syntaxJavaComment}
        \ | hi Todo         guifg={syntaxJavaDocTag}
        \ | hi Number       guifg={syntaxJavaNumber}
        \ | hi Constant     guifg={syntaxJavaConstant}
        \ | hi Function     guifg={syntaxJavaFunction}
        \ | hi Structure    guifg={syntaxJavaClass}
        \ | hi Type         guifg={syntaxJavaType}
        \ | hi Identifier   guifg={syntaxJavaVariable}
        \ | hi Operator     guifg={syntaxJavaOperator}
        \ | hi Delimiter    guifg={syntaxJavaPunctuation}

  autocmd FileType sh,bash hi Keyword    guifg={syntaxShellKeyword}
        \ | hi Function     guifg={syntaxShellExternalCommand}
        \ | hi Identifier   guifg={syntaxShellVariable}
        \ | hi String       guifg={syntaxShellString}
        \ | hi Comment      guifg={syntaxShellComment}
        \ | hi Number       guifg={syntaxShellNumber}
        \ | hi Operator     guifg={syntaxShellOperator}
        \ | hi Delimiter    guifg={syntaxShellPunctuation}

  autocmd FileType python hi Keyword     guifg={syntaxPythonKeyword}
        \ | hi PreProc      guifg={syntaxPythonDecorator}
        \ | hi Function     guifg={syntaxPythonFunction}
        \ | hi Special      guifg={syntaxPythonBuiltin}
        \ | hi String       guifg={syntaxPythonString}
        \ | hi Comment      guifg={syntaxPythonComment}
        \ | hi Number       guifg={syntaxPythonNumber}
        \ | hi Structure    guifg={syntaxPythonClass}
        \ | hi Operator     guifg={syntaxPythonOperator}
        \ | hi Delimiter    guifg={syntaxPythonPunctuation}

  autocmd FileType css,scss,less hi Identifier guifg={syntaxCssSelector}
        \ | hi Type         guifg={syntaxCssPropertyName}
        \ | hi Constant     guifg={syntaxCssPropertyValue}
        \ | hi PreProc      guifg={syntaxCssAttributeName}
        \ | hi Function     guifg={syntaxCssFunction}
        \ | hi Number       guifg={syntaxCssHash}
        \ | hi Special      guifg={syntaxCssImportant}
        \ | hi Statement    guifg={syntaxCssPseudo}
        \ | hi String       guifg={syntaxCssUrl}
        \ | hi Delimiter    guifg={syntaxCssColon}
        \ | hi Comment      guifg={syntaxCssComment}

  autocmd FileType xml,html hi Statement guifg={syntaxXmlTagName}
        \ | hi Delimiter    guifg={syntaxXmlTag}
        \ | hi Type         guifg={syntaxXmlAttributeName}
        \ | hi String       guifg={syntaxXmlAttributeValue}
        \ | hi Special      guifg={syntaxXmlEntityReference}
        \ | hi Comment      guifg={syntaxXmlComment}
        \ | hi Identifier   guifg={syntaxXmlCustomTagName}
augroup END
