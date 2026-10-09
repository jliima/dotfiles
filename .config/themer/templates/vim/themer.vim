" Themer colorscheme for Vim and Neovim, with the same per-language syntax colors as the other editors (Java, JSON,
" XML, Shell, CSS, Python and YAML), read from the IntelliJ scheme. Not activated automatically: run `:colorscheme themer` to try it, or add that line to your
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
hi Operator     guifg={{ syntax-variable }}
hi PreProc      guifg={{ syntax-annotation }}
hi Special      guifg={{ syntax-escape }}
hi SpecialChar  guifg={{ syntax-escape }}
hi Delimiter    guifg={{ syntax-punctuation }}
hi Todo         guifg={{ syntax-doc-tag }}
hi Error        guifg={{ danger }}
hi Warning      guifg={{ warning }}

" Per-language groups, one color per syntax group as IntelliJ draws it (see the language tokens in the theme).
hi javaExternal guifg={{ syntax-keyword }}
hi javaScopeDecl guifg={{ syntax-keyword }}
hi javaStorageClass guifg={{ syntax-keyword }}
hi javaConceptKind guifg={{ syntax-keyword }}
hi javaClassDecl guifg={{ syntax-keyword }}
hi javaMethodDecl guifg={{ syntax-keyword }}
hi javaStatement guifg={{ syntax-keyword }}
hi javaConditional guifg={{ syntax-keyword }}
hi javaRepeat guifg={{ syntax-keyword }}
hi javaBranch guifg={{ syntax-keyword }}
hi javaTypedef guifg={{ syntax-keyword }}
hi javaType guifg={{ syntax-keyword }}
hi javaOperator guifg={{ syntax-keyword }}
hi javaBoolean guifg={{ syntax-keyword }}
hi javaConstant guifg={{ syntax-keyword }}
hi javaExceptions guifg={{ syntax-keyword }}
hi javaLabel guifg={{ syntax-keyword }}
hi javaAnnotation guifg={{ syntax-function }}
hi javaDocSeeTag3 guifg={{ syntax-function }}
hi javaNumber guifg={{ syntax-number }}
hi javaDocNumber guifg={{ syntax-number }}
hi javaSpecialChar guifg={{ syntax-escape }}
hi javaSpecial guifg={{ syntax-escape }}
hi javaDocComment guifg={{ syntax-comment }}
hi javaCommentStar guifg={{ syntax-comment }}
hi javaCommentStart guifg={{ syntax-comment }}
hi javaLineComment guifg={{ syntax-comment }}
hi javaComment guifg={{ syntax-comment }}
hi javaCommentTitle guifg={{ syntax-comment }}
hi javaDocAuthorTag guifg={{ syntax-doc-tag }} gui=bold
hi javaDocSeeTag guifg={{ syntax-doc-tag }} gui=bold
hi javaDocTags guifg={{ syntax-doc-tag }} gui=bold
hi javaDocParam guifg={{ syntax-doc-tag }} gui=bold
hi javaParen guifg={{ syntax-punctuation }}
hi javaParen1 guifg={{ syntax-punctuation }}
hi javaParen2 guifg={{ syntax-punctuation }}
hi javaParen3 guifg={{ syntax-punctuation }}
hi javaBlockStart guifg={{ syntax-punctuation }}
hi javaBlockOtherStart guifg={{ syntax-punctuation }}
hi javaBraces guifg={{ syntax-punctuation }}
hi jsonKeyword guifg={{ syntax-json-key }}
hi jsonString guifg={{ syntax-string }}
hi jsonQuote guifg={{ syntax-string }}
hi jsonNumber guifg={{ syntax-number }}
hi jsonBoolean guifg={{ syntax-number }}
hi jsonNull guifg={{ syntax-number }}
hi jsonEscape guifg={{ syntax-escape }}
hi jsonKeywordMatch guifg={{ syntax-variable }}
hi jsonNoise guifg={{ syntax-variable }}
hi jsonBraces guifg={{ syntax-punctuation }}
hi xmlTagName guifg={{ syntax-keyword }}
hi xmlTag guifg={{ syntax-variable }}
hi xmlEndTag guifg={{ syntax-variable }}
hi xmlEqual guifg={{ syntax-variable }}
hi xmlAttribPunct guifg={{ syntax-variable }}
hi xmlProcessingDelim guifg={{ syntax-variable }}
hi xmlEntity guifg={{ syntax-variable }}
hi xmlEntityPunct guifg={{ syntax-variable }}
hi xmlCdata guifg={{ syntax-variable }}
hi xmlCdataStart guifg={{ syntax-variable }}
hi xmlCdataEnd guifg={{ syntax-variable }}
hi xmlCdataCdata guifg={{ syntax-variable }}
hi xmlAttrib guifg={{ syntax-xml-attribute }}
hi xmlString guifg={{ syntax-string }}
hi xmlComment guifg={{ syntax-comment }}
hi xmlCommentStart guifg={{ syntax-comment }}
hi xmlCommentPart guifg={{ syntax-comment }}
hi shStatement guifg={{ syntax-sh-command }}
hi bashStatement guifg={{ syntax-sh-command }}
hi shSet guifg={{ syntax-sh-command }}
hi shFunction guifg={{ syntax-sh-command }}
hi shConditional guifg={{ syntax-keyword }}
hi shLoop guifg={{ syntax-keyword }}
hi shFor guifg={{ syntax-keyword }}
hi shCase guifg={{ syntax-keyword }}
hi shCaseEsac guifg={{ syntax-keyword }}
hi shTestOpr guifg={{ syntax-variable }}
hi shCommandSub guifg={{ syntax-keyword }}
hi shDerefSimple guifg={{ syntax-variable }}
hi shDerefVar guifg={{ syntax-variable }}
hi shDeref guifg={{ syntax-variable }}
hi shShellVariables guifg={{ syntax-variable }}
hi shCmdSubRegion guifg={{ syntax-variable }}
hi shArithRegion guifg={{ syntax-variable }}
hi shDerefOp guifg={{ syntax-variable }}
hi shDerefPattern guifg={{ syntax-variable }}
hi shVariable guifg={{ syntax-variable }}
hi shVarAssign guifg={{ syntax-variable }}
hi shOption guifg={{ syntax-variable }}
hi shSetOption guifg={{ syntax-variable }}
hi shSetList guifg={{ syntax-variable }}
hi shHereDoc guifg={{ syntax-variable }}
hi shHereDoc01 guifg={{ syntax-variable }}
hi shOperator guifg={{ syntax-variable }}
hi shArithmetic guifg={{ syntax-variable }}
hi shDerefVarArray guifg={{ syntax-variable }}
hi shArrayRegion guifg={{ syntax-variable }}
hi shQuote guifg={{ syntax-string }}
hi shDoubleQuote guifg={{ syntax-string }}
hi shSingleQuote guifg={{ syntax-string }}
hi shComment guifg={{ syntax-comment }}
hi cssAtKeyword guifg={{ syntax-css-at }}
hi cssAtRule guifg={{ syntax-css-at }}
hi cssClassName guifg={{ syntax-css-class }} gui=italic
hi cssTagName guifg={{ syntax-css-class }} gui=italic
hi cssIdentifier guifg={{ syntax-css-id }}
hi cssImportant guifg={{ syntax-css-id }}
hi cssPseudoClassId guifg={{ syntax-css-pseudo }} gui=italic
hi cssFunctionName guifg={{ syntax-css-pseudo }} gui=italic
hi cssAttributeSelector guifg={{ syntax-css-pseudo }} gui=italic
hi cssCustomProp guifg={{ syntax-css-property }}
hi cssAnimationProp guifg={{ syntax-css-property }}
hi cssBackgroundProp guifg={{ syntax-css-property }}
hi cssBorderProp guifg={{ syntax-css-property }}
hi cssBoxProp guifg={{ syntax-css-property }}
hi cssColorProp guifg={{ syntax-css-property }}
hi cssDimensionProp guifg={{ syntax-css-property }}
hi cssFlexibleBoxProp guifg={{ syntax-css-property }}
hi cssFontProp guifg={{ syntax-css-property }}
hi cssGeneratedContentProp guifg={{ syntax-css-property }}
hi cssGridProp guifg={{ syntax-css-property }}
hi cssListProp guifg={{ syntax-css-property }}
hi cssMarqueeProp guifg={{ syntax-css-property }}
hi cssMultiColumnProp guifg={{ syntax-css-property }}
hi cssPagedMediaProp guifg={{ syntax-css-property }}
hi cssPositioningProp guifg={{ syntax-css-property }}
hi cssPrintProp guifg={{ syntax-css-property }}
hi cssRubyProp guifg={{ syntax-css-property }}
hi cssSpeechProp guifg={{ syntax-css-property }}
hi cssTableProp guifg={{ syntax-css-property }}
hi cssTextProp guifg={{ syntax-css-property }}
hi cssTransformProp guifg={{ syntax-css-property }}
hi cssTransitionProp guifg={{ syntax-css-property }}
hi cssUIProp guifg={{ syntax-css-property }}
hi cssAuralProp guifg={{ syntax-css-property }}
hi cssRenderProp guifg={{ syntax-css-property }}
hi cssPageProp guifg={{ syntax-css-property }}
hi cssMediaProp guifg={{ syntax-css-property }}
hi cssContentForPagedMediaProp guifg={{ syntax-css-property }}
hi cssHyerlinkProp guifg={{ syntax-css-property }}
hi cssIEUIProp guifg={{ syntax-css-property }}
hi cssColor guifg={{ syntax-css-color }}
hi cssUnitDecorators guifg={{ syntax-variable }}
hi cssFontAttr guifg={{ syntax-variable }}
hi cssCommonAttr guifg={{ syntax-variable }}
hi cssBackgroundAttr guifg={{ syntax-variable }}
hi cssSelectorOp guifg={{ syntax-variable }}
hi cssSelectorOp2 guifg={{ syntax-variable }}
hi cssValueIdent guifg={{ syntax-variable }}
hi cssValueNumber guifg={{ syntax-number }}
hi cssValueLength guifg={{ syntax-number }}
hi cssValueInteger guifg={{ syntax-number }}
hi cssValueAngle guifg={{ syntax-number }}
hi cssValueTime guifg={{ syntax-number }}
hi cssBraces guifg={{ syntax-punctuation }}
hi cssFunctionComma guifg={{ syntax-punctuation }}
hi cssAttrComma guifg={{ syntax-punctuation }}
hi cssClassNameDot guifg={{ syntax-punctuation }}
hi cssNoise guifg={{ syntax-comment }}
hi cssComment guifg={{ syntax-comment }}
hi cssStringQQ guifg={{ syntax-string }}
hi cssStringQ guifg={{ syntax-string }}
hi pythonStatement guifg={{ syntax-py-keyword }}
hi pythonConditional guifg={{ syntax-py-keyword }}
hi pythonRepeat guifg={{ syntax-py-keyword }}
hi pythonOperator guifg={{ syntax-py-keyword }}
hi pythonInclude guifg={{ syntax-py-keyword }}
hi pythonException guifg={{ syntax-py-keyword }}
hi pythonAsync guifg={{ syntax-py-keyword }}
hi pythonLambda guifg={{ syntax-py-keyword }}
hi pythonExceptions guifg={{ syntax-function }}
hi pythonClass guifg={{ syntax-function }}
hi pythonFunction guifg={{ syntax-function }}
hi pythonDecorator guifg={{ syntax-keyword }}
hi pythonDecoratorName guifg={{ syntax-keyword }}
hi pythonBuiltin guifg={{ syntax-variable }}
hi pythonClassVar guifg={{ syntax-variable }}
hi pythonFStringField guifg={{ syntax-variable }}
hi pythonBytes guifg={{ syntax-py-bytes }}
hi pythonEscape guifg={{ syntax-escape }}
hi pythonFStringDelimiter guifg={{ syntax-escape }}
hi yamlBlockMappingKey guifg={{ syntax-yaml-key }}
hi yamlBlockMappingMerge guifg={{ syntax-yaml-key }}
hi yamlBlockMappingDelimiter guifg={{ syntax-variable }}
hi yamlInteger guifg={{ syntax-variable }}
hi yamlBool guifg={{ syntax-variable }}
hi yamlNull guifg={{ syntax-variable }}
hi yamlFlowIndicator guifg={{ syntax-variable }}
hi yamlFlowCollection guifg={{ syntax-variable }}
hi yamlBlockCollectionItemStart guifg={{ syntax-variable }}
hi yamlBlockScalarHeader guifg={{ syntax-variable }}
hi yamlPlainScalar guifg={{ syntax-variable }}
hi yamlFloat guifg={{ syntax-variable }}
hi yamlAnchor guifg={{ syntax-yaml-anchor }}
hi yamlAlias guifg={{ syntax-yaml-anchor }}

" Shell prints the $ of an expansion with the generic PreProc group; IntelliJ draws it as a keyword
augroup themer_sh_expansion
  autocmd!
  autocmd FileType sh,bash,zsh hi PreProc guifg={{ syntax-keyword }}
augroup END

" JSON draws keys, quotes included, in one color; the stock syntax colors the quotes like any string
augroup themer_json_keys
  autocmd!
  autocmd Syntax json syntax match themerJsonKey /"\%([^"\\]\|\\.\)*"\ze\s*:/
augroup END
hi themerJsonKey guifg={{ syntax-json-key }}
