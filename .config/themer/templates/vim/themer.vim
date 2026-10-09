" Themer colorscheme for Neovim (and Vim). The editor and plugin colors follow the IntelliJ scheme, the syntax
" colors are the same tokens every other editor uses: Treesitter and LSP groups for the parsers Neovim ships (Lua,
" Bash, Markdown, HTML, C, diff, Vim), and Vim's own syntax groups for the languages without one (Java, JSON, XML,
" Shell, CSS, Python, YAML). Select it with `colorscheme themer` (init.lua does, with a fallback if the file is
" missing).

hi clear
if exists('syntax_on')
  syntax reset
endif
let g:colors_name = 'themer'
set background={{ variant }}

" ---- Editor -------------------------------------------------------------------------------------------------------
hi Normal         guifg={{ text }} guibg={{ bg }}
hi NormalNC       guifg={{ text }} guibg={{ bg }}
hi NormalFloat    guifg={{ text }} guibg={{ surface-raised }}
hi FloatBorder    guifg={{ line-strong }} guibg={{ surface-raised }}
hi FloatTitle     guifg={{ accent }} guibg={{ surface-raised }} gui=bold
hi FloatFooter    guifg={{ text-subtle }} guibg={{ surface-raised }}
hi Cursor         guifg={{ bg }} guibg={{ text }}
hi lCursor        guifg={{ bg }} guibg={{ text }}
hi TermCursor     guifg={{ bg }} guibg={{ text }}
hi CursorLine     guibg={{ surface-active }}
hi CursorColumn   guibg={{ surface-active }}
hi ColorColumn    guibg={{ surface }}
hi LineNr         guifg={{ text-disabled }} guibg={{ bg-sunken }}
hi LineNrAbove    guifg={{ text-disabled }} guibg={{ bg-sunken }}
hi LineNrBelow    guifg={{ text-disabled }} guibg={{ bg-sunken }}
hi CursorLineNr   guifg={{ text }} guibg={{ surface-active }}
hi CursorLineSign guibg={{ surface-active }}
hi CursorLineFold guibg={{ surface-active }}
hi SignColumn     guifg={{ text-subtle }} guibg={{ bg-sunken }}
hi FoldColumn     guifg={{ text-disabled }} guibg={{ bg-sunken }}
hi Folded         guifg={{ text-subtle }} guibg={{ surface }}
hi WinSeparator   guifg={{ line }} guibg={{ bg }}
hi VertSplit      guifg={{ line }} guibg={{ bg }}
hi StatusLine     guifg={{ text }} guibg={{ bg-sunken }}
hi StatusLineNC   guifg={{ text-faint }} guibg={{ bg-sunken }}
hi StatusLineTerm guifg={{ text }} guibg={{ bg-sunken }}
hi StatusLineTermNC guifg={{ text-faint }} guibg={{ bg-sunken }}
hi WinBar         guifg={{ text }} guibg={{ bg }} gui=bold
hi WinBarNC       guifg={{ text-faint }} guibg={{ bg }}
hi TabLine        guifg={{ text-subtle }} guibg={{ bg-sunken }}
hi TabLineSel     guifg={{ text-bright }} guibg={{ bg }} gui=bold
hi TabLineFill    guibg={{ bg-sunken }}
hi Visual         guibg={{ selection }}
hi VisualNOS      guibg={{ selection }}
hi Search         guifg={{ text-bright }} guibg={{ surface-active }}
hi CurSearch      guifg={{ on-accent }} guibg={{ accent }}
hi IncSearch      guifg={{ on-accent }} guibg={{ accent }}
hi Substitute     guifg={{ on-accent }} guibg={{ danger }}
hi MatchParen     guifg={{ text-bright }} guibg={{ surface-active }} gui=bold
hi NonText        guifg={{ text-disabled }}
hi EndOfBuffer    guifg={{ bg }}
hi Whitespace     guifg={{ line }}
hi SpecialKey     guifg={{ text-disabled }}
hi Conceal        guifg={{ text-subtle }}
hi Directory      guifg={{ syntax-function }}
hi Title          guifg={{ syntax-heading }} gui=bold
hi ErrorMsg       guifg={{ danger }}
hi WarningMsg     guifg={{ warning }}
hi ModeMsg        guifg={{ text }}
hi MoreMsg        guifg={{ success }}
hi Question       guifg={{ success }}
hi MsgArea        guifg={{ text }} guibg={{ bg }}
hi MsgSeparator   guifg={{ line }} guibg={{ bg-sunken }}
hi WildMenu       guifg={{ kde-selection-text }} guibg={{ kde-selection }}
hi QuickFixLine   guibg={{ kde-selection }}
hi Pmenu          guifg={{ text }} guibg={{ surface-raised }}
hi PmenuSel       guifg={{ kde-selection-text }} guibg={{ kde-selection }}
hi PmenuKind      guifg={{ syntax-type }} guibg={{ surface-raised }}
hi PmenuKindSel   guifg={{ syntax-type }} guibg={{ kde-selection }}
hi PmenuExtra     guifg={{ text-subtle }} guibg={{ surface-raised }}
hi PmenuExtraSel  guifg={{ text-subtle }} guibg={{ kde-selection }}
hi PmenuSbar      guibg={{ surface-active }}
hi PmenuThumb     guibg={{ line-strong }}
hi PmenuMatch     guifg={{ accent }} guibg={{ surface-raised }} gui=bold
hi PmenuMatchSel  guifg={{ accent }} guibg={{ kde-selection }} gui=bold

" Spelling, diffs and diagnostics: the IntelliJ colors (red errors, orange warnings, blue modified lines, green added)
hi SpellBad       guisp={{ danger }} gui=undercurl
hi SpellCap       guisp={{ warning }} gui=undercurl
hi SpellLocal     guisp={{ info }} gui=undercurl
hi SpellRare      guisp={{ syntax-annotation }} gui=undercurl
hi DiffAdd        guibg={{ success-soft }}
hi DiffChange     guibg={{ accent-soft }}
hi DiffDelete     guifg={{ danger }} guibg={{ danger-soft }}
hi DiffText       guibg={{ blue-mid }}
hi Added          guifg={{ success }}
hi Changed        guifg={{ accent }}
hi Removed        guifg={{ danger }}
hi DiagnosticError guifg={{ danger }}
hi DiagnosticWarn guifg={{ warning }}
hi DiagnosticInfo guifg={{ info }}
hi DiagnosticHint guifg={{ text-subtle }}
hi DiagnosticOk   guifg={{ success }}
hi DiagnosticUnderlineError guisp={{ danger }} gui=undercurl
hi DiagnosticUnderlineWarn guisp={{ warning }} gui=undercurl
hi DiagnosticUnderlineInfo guisp={{ info }} gui=undercurl
hi DiagnosticUnderlineHint guisp={{ text-subtle }} gui=undercurl
hi DiagnosticUnderlineOk guisp={{ success }} gui=underline
hi DiagnosticVirtualTextError guifg={{ danger }} guibg={{ danger-soft }}
hi DiagnosticVirtualTextWarn guifg={{ warning }} guibg={{ warning-soft }}
hi DiagnosticVirtualTextInfo guifg={{ info }} guibg={{ info-soft }}
hi DiagnosticVirtualTextHint guifg={{ text-subtle }} guibg={{ surface }}
hi DiagnosticVirtualTextOk guifg={{ success }} guibg={{ success-soft }}
hi DiagnosticSignError guifg={{ danger }} guibg={{ bg-sunken }}
hi DiagnosticSignWarn guifg={{ warning }} guibg={{ bg-sunken }}
hi DiagnosticSignInfo guifg={{ info }} guibg={{ bg-sunken }}
hi DiagnosticSignHint guifg={{ text-subtle }} guibg={{ bg-sunken }}
hi DiagnosticSignOk guifg={{ success }} guibg={{ bg-sunken }}
hi DiagnosticDeprecated guisp={{ warning }} gui=strikethrough
hi DiagnosticUnnecessary guifg={{ text-disabled }}
hi LspReferenceText guibg={{ surface-active }}
hi LspReferenceRead guibg={{ surface-active }}
hi LspReferenceWrite guibg={{ surface-active }} gui=underline
hi LspReferenceTarget guibg={{ surface-active }}
hi LspInlayHint   guifg={{ text-subtle }} guibg={{ surface }}
hi LspCodeLens    guifg={{ text-subtle }}
hi LspSignatureActiveParameter guifg={{ accent }} gui=bold,underline

" ---- Syntax (Vim's generic groups) --------------------------------------------------------------------------------
hi Comment      guifg={{ syntax-comment }}
hi String       guifg={{ syntax-string }}
hi Character    guifg={{ syntax-string }}
hi Number       guifg={{ syntax-number }}
hi Boolean      guifg={{ syntax-keyword }}
hi Float        guifg={{ syntax-number }}
hi Keyword      guifg={{ syntax-keyword }}
hi Statement    guifg={{ syntax-keyword }}
hi Conditional  guifg={{ syntax-keyword }}
hi Repeat       guifg={{ syntax-keyword }}
hi Label        guifg={{ syntax-keyword }}
hi Exception    guifg={{ syntax-keyword }}
hi Function     guifg={{ syntax-function }}
hi Identifier   guifg={{ syntax-variable }}
hi Type         guifg={{ syntax-type }}
hi StorageClass guifg={{ syntax-keyword }}
hi Structure    guifg={{ syntax-class }}
hi Typedef      guifg={{ syntax-type }}
hi Constant     guifg={{ syntax-constant }}
hi Operator     guifg={{ syntax-variable }}
hi PreProc      guifg={{ syntax-annotation }}
hi Include      guifg={{ syntax-keyword }}
hi Define       guifg={{ syntax-annotation }}
hi Macro        guifg={{ syntax-annotation }}
hi PreCondit    guifg={{ syntax-annotation }}
hi Special      guifg={{ syntax-escape }}
hi SpecialChar  guifg={{ syntax-escape }}
hi SpecialComment guifg={{ syntax-doc-tag }} gui=bold
hi Tag          guifg={{ syntax-tag }}
hi Delimiter    guifg={{ syntax-punctuation }}
hi Debug        guifg={{ syntax-doc-tag }}
hi Underlined   guifg={{ syntax-link }} gui=underline
hi Bold         gui=bold
hi Italic       gui=italic
hi Ignore       guifg={{ text-disabled }}
hi Todo         guifg={{ syntax-number }} gui=bold
hi Error        guifg={{ danger }}
hi Warning      guifg={{ warning }}

" ---- Treesitter (the captures of the parsers Neovim ships) ---------------------------------------------------
hi clear @variable
hi! link @variable Identifier
hi @variable.builtin     guifg={{ syntax-type }} gui=italic
hi @variable.parameter   guifg={{ syntax-variable }}
hi @variable.member      guifg={{ syntax-variable }}
hi @constant             guifg={{ syntax-constant }}
hi @constant.builtin     guifg={{ syntax-keyword }}
hi @module               guifg={{ syntax-type }}
hi @module.builtin       guifg={{ syntax-type }}
hi @label                guifg={{ syntax-keyword }}
hi @string               guifg={{ syntax-string }}
hi @string.escape        guifg={{ syntax-escape }}
hi @string.special       guifg={{ syntax-escape }}
hi @string.special.url   guifg={{ syntax-url }} gui=underline
hi @string.regexp        guifg={{ syntax-regex }}
hi @character            guifg={{ syntax-string }}
hi @number               guifg={{ syntax-number }}
hi @number.float         guifg={{ syntax-number }}
hi @boolean              guifg={{ syntax-keyword }}
hi @type                 guifg={{ syntax-type }}
hi @type.builtin         guifg={{ syntax-keyword }}
hi @type.definition      guifg={{ syntax-class }}
hi @attribute            guifg={{ syntax-annotation }}
hi @attribute.builtin    guifg={{ syntax-annotation }}
hi @property             guifg={{ syntax-property }}
hi @function             guifg={{ syntax-function }}
hi @function.builtin     guifg={{ syntax-function }}
hi @function.call        guifg={{ syntax-function }}
hi @function.macro       guifg={{ syntax-annotation }}
hi @function.method      guifg={{ syntax-function }}
hi @function.method.call guifg={{ syntax-function }}
hi @constructor          guifg={{ syntax-class }}
hi @operator             guifg={{ syntax-variable }}
hi @keyword              guifg={{ syntax-keyword }}
hi @keyword.function     guifg={{ syntax-keyword }}
hi @keyword.operator     guifg={{ syntax-keyword }}
hi @keyword.return       guifg={{ syntax-keyword }}
hi @keyword.import       guifg={{ syntax-keyword }}
hi @keyword.exception    guifg={{ syntax-keyword }}
hi @keyword.directive    guifg={{ syntax-annotation }}
hi @keyword.directive.define guifg={{ syntax-annotation }}
hi @punctuation.delimiter guifg={{ syntax-punctuation }}
hi @punctuation.bracket  guifg={{ syntax-punctuation }}
hi @punctuation.special  guifg={{ syntax-escape }}
hi @comment              guifg={{ syntax-comment }}
hi @comment.documentation guifg={{ syntax-comment }}
hi @comment.error        guifg={{ danger }} gui=bold
hi @comment.warning      guifg={{ warning }} gui=bold
hi @comment.todo         guifg={{ syntax-number }} gui=bold
hi @comment.note         guifg={{ info }} gui=bold
hi @diff.plus            guifg={{ success }}
hi @diff.minus           guifg={{ danger }}
hi @diff.delta           guifg={{ accent }}
hi @tag                  guifg={{ syntax-tag }}
hi @tag.builtin          guifg={{ syntax-tag }}
hi @tag.attribute        guifg={{ syntax-attribute }}
hi @tag.delimiter        guifg={{ syntax-comment }}

" Lua (IntelliJ: self like a type in italics, std API in the function color)
hi @variable.builtin.lua guifg={{ syntax-type }} gui=italic
hi @variable.parameter.lua guifg={{ syntax-doc-tag }}
hi @module.builtin.lua   guifg={{ syntax-function }}
hi @function.builtin.lua guifg={{ syntax-function }}
hi @comment.documentation.lua guifg={{ syntax-comment }}
hi @lsp.type.comment.lua guifg={{ syntax-comment }}

" Shell (IntelliJ: commands in the function color, keywords green, variables and the $ plain)
hi @function.call.bash   guifg={{ syntax-sh-command }}
hi @function.builtin.bash guifg={{ syntax-sh-command }}
hi @function.bash        guifg={{ syntax-sh-command }}
hi @variable.bash        guifg={{ syntax-variable }}
hi @constant.bash        guifg={{ syntax-variable }}
hi @operator.bash        guifg={{ syntax-variable }}
hi @punctuation.special.bash guifg={{ syntax-keyword }}
hi @keyword.bash         guifg={{ syntax-keyword }}
hi @keyword.conditional.bash guifg={{ syntax-keyword }}
hi @keyword.repeat.bash  guifg={{ syntax-keyword }}
hi @string.bash          guifg={{ syntax-string }}
hi @number.bash          guifg={{ syntax-number }}
hi @comment.bash         guifg={{ syntax-comment }}
hi @string.heredoc.bash  guifg={{ syntax-variable }}
hi @markup.heading.bash  guifg={{ syntax-variable }}

" Markdown (IntelliJ: accent headings, bold and italic in the doc tag color, code spans in the annotation color)
hi @markup.heading       guifg={{ accent }} gui=bold
hi @markup.heading.1     guifg={{ accent }} gui=bold
hi @markup.heading.2     guifg={{ accent }} gui=bold
hi @markup.heading.3     guifg={{ accent }} gui=bold
hi @markup.heading.4     guifg={{ accent }} gui=bold
hi @markup.heading.5     guifg={{ accent }} gui=bold
hi @markup.heading.6     guifg={{ accent }} gui=bold
hi @markup.strong        guifg={{ syntax-doc-tag }} gui=bold
hi @markup.italic        guifg={{ syntax-doc-tag }} gui=italic
hi @markup.strikethrough gui=strikethrough
hi @markup.underline     gui=underline
hi @markup.quote         guifg={{ syntax-keyword }} gui=italic
hi @markup.math          guifg={{ syntax-escape }}
hi @markup.link          guifg={{ syntax-function }}
hi @markup.link.label    guifg={{ syntax-function }} gui=underline
hi @markup.link.url      guifg={{ syntax-string }}
hi @markup.raw           guifg={{ syntax-annotation }} gui=italic
hi @markup.raw.block     guifg={{ text }}
hi @markup.list          guifg={{ syntax-doc-tag }}
hi @markup.list.checked  guifg={{ success }}
hi @markup.list.unchecked guifg={{ text-subtle }}
hi @punctuation.special.markdown guifg={{ syntax-comment }}
hi @markup.heading.marker.markdown guifg={{ syntax-comment }}
hi @markup.list.markdown guifg={{ syntax-doc-tag }} gui=italic
hi @markup.quote.markdown guifg={{ syntax-keyword }} gui=italic
hi @markup.raw.delimiter.markdown guifg={{ syntax-comment }}
hi @markup.italic.markdown_inline guifg={{ syntax-doc-tag }} gui=italic
hi @markup.strong.markdown_inline guifg={{ syntax-doc-tag }} gui=bold
hi @markup.raw.markdown_inline guifg={{ syntax-annotation }} gui=italic
hi @markup.link.label.markdown_inline guifg={{ syntax-doc-tag }}
hi @markup.link.url.markdown_inline guifg={{ syntax-string }}
hi @markup.link.markdown_inline guifg={{ syntax-comment }}
hi @label.markdown       guifg={{ syntax-comment }}

" HTML (IntelliJ: tag names green, the angle brackets and attribute names in other colors)
hi @tag.html             guifg={{ syntax-keyword }}
hi @tag.delimiter.html   guifg={{ syntax-comment }}
hi @tag.attribute.html   guifg={{ syntax-doc-tag }}
hi @string.html          guifg={{ syntax-string }}
hi @markup.heading.html  guifg={{ text }}
hi @markup.link.html     guifg={{ syntax-string }}

" C (the classic groups in the IntelliJ colors)
hi @keyword.directive.c  guifg={{ syntax-annotation }}
hi @keyword.import.c     guifg={{ syntax-annotation }}
hi @type.builtin.c       guifg={{ syntax-keyword }}
hi @lsp.type.macro       guifg={{ syntax-annotation }}

" LSP semantic tokens use the same palette as the Treesitter captures
hi @lsp.type.class       guifg={{ syntax-class }}
hi @lsp.type.interface   guifg={{ syntax-class }}
hi @lsp.type.enum        guifg={{ syntax-class }}
hi @lsp.type.struct      guifg={{ syntax-class }}
hi @lsp.type.type        guifg={{ syntax-type }}
hi @lsp.type.typeParameter guifg={{ syntax-type }}
hi @lsp.type.namespace   guifg={{ syntax-type }}
hi @lsp.type.function    guifg={{ syntax-function }}
hi @lsp.type.method      guifg={{ syntax-function }}
hi @lsp.type.decorator   guifg={{ syntax-annotation }}
hi @lsp.type.property    guifg={{ syntax-property }}
hi @lsp.type.enumMember  guifg={{ syntax-constant }}
hi @lsp.type.variable    guifg={{ syntax-variable }}
hi @lsp.type.parameter   guifg={{ syntax-variable }}
hi @lsp.type.keyword     guifg={{ syntax-keyword }}
hi @lsp.type.string      guifg={{ syntax-string }}
hi @lsp.type.number      guifg={{ syntax-number }}
hi @lsp.type.operator    guifg={{ syntax-variable }}
hi @lsp.type.comment     guifg={{ syntax-comment }}
hi @lsp.typemod.variable.readonly guifg={{ syntax-constant }}
hi @lsp.typemod.variable.defaultLibrary guifg={{ syntax-type }}
hi @lsp.typemod.function.defaultLibrary guifg={{ syntax-function }}
hi @lsp.typemod.method.defaultLibrary guifg={{ syntax-function }}

" ---- Plugins (kickstart.nvim: Telescope, blink.cmp, which-key, gitsigns, mini, neo-tree, ...) --------------------
hi GitSignsAdd          guifg={{ success }} guibg={{ bg-sunken }}
hi GitSignsChange       guifg={{ accent }} guibg={{ bg-sunken }}
hi GitSignsDelete       guifg={{ danger }} guibg={{ bg-sunken }}
hi GitSignsAddNr        guifg={{ success }}
hi GitSignsChangeNr     guifg={{ accent }}
hi GitSignsDeleteNr     guifg={{ danger }}
hi GitSignsAddInline    guibg={{ green-mid }}
hi GitSignsChangeInline guibg={{ blue-mid }}
hi GitSignsDeleteInline guibg={{ red-mid }}
hi TelescopeNormal      guifg={{ text }} guibg={{ surface-raised }}
hi TelescopeBorder      guifg={{ line-strong }} guibg={{ surface-raised }}
hi TelescopeTitle       guifg={{ accent }} guibg={{ surface-raised }} gui=bold
hi TelescopePromptNormal guifg={{ text-bright }} guibg={{ surface-active }}
hi TelescopePromptBorder guifg={{ surface-active }} guibg={{ surface-active }}
hi TelescopePromptTitle guifg={{ on-accent }} guibg={{ accent }} gui=bold
hi TelescopePromptPrefix guifg={{ accent }} guibg={{ surface-active }}
hi TelescopePromptCounter guifg={{ text-subtle }}
hi TelescopeResultsTitle guifg={{ text-subtle }} guibg={{ surface-raised }}
hi TelescopePreviewTitle guifg={{ on-accent }} guibg={{ success }} gui=bold
hi TelescopeSelection   guifg={{ kde-selection-text }} guibg={{ kde-selection }}
hi TelescopeSelectionCaret guifg={{ accent }} guibg={{ kde-selection }}
hi TelescopeMultiSelection guifg={{ syntax-annotation }}
hi TelescopeMatching    guifg={{ accent }} gui=bold
hi BlinkCmpMenu         guifg={{ text }} guibg={{ surface-raised }}
hi BlinkCmpMenuBorder   guifg={{ line-strong }} guibg={{ surface-raised }}
hi BlinkCmpMenuSelection guifg={{ kde-selection-text }} guibg={{ kde-selection }}
hi BlinkCmpScrollBarThumb guibg={{ line-strong }}
hi BlinkCmpScrollBarGutter guibg={{ surface-active }}
hi BlinkCmpLabel        guifg={{ text }}
hi BlinkCmpLabelDeprecated guifg={{ text-disabled }} gui=strikethrough
hi BlinkCmpLabelMatch   guifg={{ accent }} gui=bold
hi BlinkCmpLabelDetail  guifg={{ text-subtle }}
hi BlinkCmpLabelDescription guifg={{ text-subtle }}
hi BlinkCmpKind         guifg={{ syntax-type }}
hi BlinkCmpKindText     guifg={{ text-subtle }}
hi BlinkCmpKindMethod   guifg={{ syntax-function }}
hi BlinkCmpKindFunction guifg={{ syntax-function }}
hi BlinkCmpKindConstructor guifg={{ syntax-class }}
hi BlinkCmpKindField    guifg={{ syntax-property }}
hi BlinkCmpKindVariable guifg={{ syntax-variable }}
hi BlinkCmpKindClass    guifg={{ syntax-class }}
hi BlinkCmpKindInterface guifg={{ syntax-class }}
hi BlinkCmpKindModule   guifg={{ syntax-type }}
hi BlinkCmpKindProperty guifg={{ syntax-property }}
hi BlinkCmpKindUnit     guifg={{ syntax-number }}
hi BlinkCmpKindValue    guifg={{ syntax-number }}
hi BlinkCmpKindEnum     guifg={{ syntax-class }}
hi BlinkCmpKindKeyword  guifg={{ syntax-keyword }}
hi BlinkCmpKindSnippet  guifg={{ syntax-annotation }}
hi BlinkCmpKindColor    guifg={{ syntax-css-color }}
hi BlinkCmpKindFile     guifg={{ syntax-string }}
hi BlinkCmpKindReference guifg={{ syntax-link }}
hi BlinkCmpKindFolder   guifg={{ syntax-function }}
hi BlinkCmpKindEnumMember guifg={{ syntax-constant }}
hi BlinkCmpKindConstant guifg={{ syntax-constant }}
hi BlinkCmpKindStruct   guifg={{ syntax-class }}
hi BlinkCmpKindEvent    guifg={{ syntax-doc-tag }}
hi BlinkCmpKindOperator guifg={{ syntax-variable }}
hi BlinkCmpKindTypeParameter guifg={{ syntax-type }}
hi BlinkCmpDoc          guifg={{ text }} guibg={{ surface-raised }}
hi BlinkCmpDocBorder    guifg={{ line-strong }} guibg={{ surface-raised }}
hi BlinkCmpDocSeparator guifg={{ line-strong }} guibg={{ surface-raised }}
hi BlinkCmpDocCursorLine guibg={{ surface-active }}
hi BlinkCmpSignatureHelp guifg={{ text }} guibg={{ surface-raised }}
hi BlinkCmpSignatureHelpBorder guifg={{ line-strong }} guibg={{ surface-raised }}
hi BlinkCmpSignatureHelpActiveParameter guifg={{ accent }} gui=bold,underline
hi BlinkCmpGhostText    guifg={{ text-disabled }}
hi WhichKey             guifg={{ syntax-function }}
hi WhichKeyGroup        guifg={{ syntax-annotation }}
hi WhichKeyDesc         guifg={{ text }}
hi WhichKeySeparator    guifg={{ text-disabled }}
hi WhichKeyIcon         guifg={{ accent }}
hi WhichKeyValue        guifg={{ text-subtle }}
hi WhichKeyNormal       guifg={{ text }} guibg={{ surface-raised }}
hi WhichKeyBorder       guifg={{ line-strong }} guibg={{ surface-raised }}
hi WhichKeyTitle        guifg={{ accent }} guibg={{ surface-raised }} gui=bold
hi IblIndent            guifg={{ line }} gui=nocombine
hi IblScope             guifg={{ line-strong }} gui=nocombine
hi MiniStatuslineModeNormal  guifg={{ on-accent }} guibg={{ accent }} gui=bold
hi MiniStatuslineModeInsert  guifg={{ on-accent }} guibg={{ success }} gui=bold
hi MiniStatuslineModeVisual  guifg={{ on-accent }} guibg={{ syntax-annotation }} gui=bold
hi MiniStatuslineModeReplace guifg={{ on-accent }} guibg={{ danger }} gui=bold
hi MiniStatuslineModeCommand guifg={{ on-accent }} guibg={{ warning }} gui=bold
hi MiniStatuslineModeOther   guifg={{ on-accent }} guibg={{ info }} gui=bold
hi MiniStatuslineDevinfo     guifg={{ text-muted }} guibg={{ surface-active }}
hi MiniStatuslineFilename    guifg={{ text }} guibg={{ bg-sunken }}
hi MiniStatuslineFileinfo    guifg={{ text-muted }} guibg={{ surface-active }}
hi MiniStatuslineInactive    guifg={{ text-faint }} guibg={{ bg-sunken }}
hi NeoTreeNormal        guifg={{ text }} guibg={{ bg-sunken }}
hi NeoTreeNormalNC      guifg={{ text }} guibg={{ bg-sunken }}
hi NeoTreeEndOfBuffer   guifg={{ bg-sunken }} guibg={{ bg-sunken }}
hi NeoTreeWinSeparator  guifg={{ line }} guibg={{ bg }}
hi NeoTreeCursorLine    guibg={{ kde-selection }}
hi NeoTreeDirectoryName guifg={{ text }}
hi NeoTreeDirectoryIcon guifg={{ syntax-function }}
hi NeoTreeRootName      guifg={{ syntax-heading }} gui=bold
hi NeoTreeGitAdded      guifg={{ success }}
hi NeoTreeGitModified   guifg={{ accent }}
hi NeoTreeGitDeleted    guifg={{ danger }}
hi NeoTreeGitUntracked  guifg={{ warning }}
hi NeoTreeGitIgnored    guifg={{ text-disabled }}
hi NeoTreeDotfile       guifg={{ text-subtle }}
hi FidgetTitle          guifg={{ syntax-function }}
hi FidgetTask           guifg={{ text-subtle }}
hi LazyNormal           guifg={{ text }} guibg={{ surface-raised }}
hi LazyH1               guifg={{ on-accent }} guibg={{ accent }} gui=bold
hi LazyButton           guifg={{ text }} guibg={{ surface-active }}
hi LazyButtonActive     guifg={{ on-accent }} guibg={{ accent }} gui=bold
hi LazyReasonPlugin     guifg={{ syntax-function }}
hi LazySpecial          guifg={{ syntax-annotation }}
hi MasonNormal          guifg={{ text }} guibg={{ surface-raised }}
hi MasonHeader          guifg={{ on-accent }} guibg={{ accent }} gui=bold
hi MasonHighlight       guifg={{ accent }}
hi MasonHighlightBlock  guifg={{ on-accent }} guibg={{ accent }}
hi MasonMuted           guifg={{ text-subtle }}
hi MasonMutedBlock      guifg={{ text }} guibg={{ surface-active }}

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
