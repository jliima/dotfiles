"use strict";
Object.defineProperty(exports, "__esModule", { value: true });

// Function to load custom colors - called each time theme is generated
function loadCustomColors() {
  try {
    const fs = require('fs');
    const path = require('path');
    const os = require('os');
    const customColorsPath = path.join(os.homedir(), '.cache', 'wal', 'colors-vscode.js');
      
    // Clear require cache to ensure fresh load
    if (require.cache[customColorsPath]) {
      delete require.cache[customColorsPath];
    }
    // Try to resolve the absolute path
    let resolvedPath;
    try {
      resolvedPath = require.resolve(customColorsPath);
      if (require.cache[resolvedPath]) {
        delete require.cache[resolvedPath];
      }
    } catch (e) {
      // Path not in cache, that's fine
    }
      
    // Require the file fresh
    return require(customColorsPath);
  } catch (e) {
    // Custom colors not available, will use default color array indices
    return null;
  }
}

function createCustomColors(colors) {
  const loadedCustomColors = loadCustomColors();
  const loadedSpecial = loadedCustomColors && loadedCustomColors.special ? loadedCustomColors.special : {};

  const generatedSpecial = {
    background: colors[0].hex(),
    foreground: colors[7].hex(),
    backgroundAlt: colors[0].hex(),
    surface: colors[0].lighten(0.20).hex(),
    surfaceHover: colors[8].hex() + '33',
    overlay: colors[0].lighten(0.20).hex(),
    selection: colors[8].hex() + '77',
    highlight: colors[8].hex() + '44',
    cursor: colors[1].hex(),
    accent: colors[1].hex(),
    accentHover: colors[1].hex() + 'b3',
    accentSubtle: colors[1].hex() + '44',
    border: colors[8].hex() + '55',
    borderSubtle: colors[8].hex() + '33',
    borderFocus: colors[1].hex() + '77',
    textInverse: colors[0].hex(),
    textSecondary: colors[7].hex() + '99',
    textMuted: colors[7].hex() + 'b0',
    textDisabled: colors[8].hex() + '77',
    textLink: colors[13].hex(),
    success: colors[2].hex(),
    info: colors[12].hex(),
    warning: colors[3].hex(),
    error: colors[4].hex(),
    green3: colors[10].hex(),
    red3: colors[3].hex(),
    cyan5: colors[6].hex(),
    syntaxComment: colors[8].hex() + 'b0',
    syntaxStringEscape: colors[14].hex(),
    syntaxKeyword: colors[2].hex(),
    syntaxFunction: colors[12].hex(),
    syntaxString: colors[13].hex(),
    syntaxNumber: colors[1].hex(),
    syntaxVariable: colors[15].hex(),
    syntaxPunctuation: colors[15].hex()
  };

  const missingKeys = Object.keys(generatedSpecial).filter((key) => loadedSpecial[key] === undefined);
  if (!loadedCustomColors || !loadedCustomColors.special || missingKeys.length > 0) {
    console.warn('[wal-theme] Missing custom colors, generating defaults from colors[0..15].');
  }

  return {
    ...(loadedCustomColors || {}),
    special: {
      ...generatedSpecial,
      ...loadedSpecial
    }
  };
}

exports.default = (colors, bordered) => {
  // Load custom colors fresh each time theme is generated and ensure defaults
  const customColors = createCustomColors(colors);

  // Colour reference https://code.visualstudio.com/docs/getstarted/theme-color-reference
  // CONTRAST COLOURS
  // --
  // BASE COLOURS
  return {
    'type': 'dark',
    'colors': {
      'focusBorder': customColors.special.borderFocus,
      'foreground': customColors.special.foreground,
      'widget.shadow': colors[0].darken(0.25).hex(),
      'selection.background': customColors.special.selection,
      // TEXT COLOURS
      'textBlockQuote.background': customColors.special.surface,
      'textLink.foreground': customColors.special.textLink,
      'textLink.activeForeground': customColors.special.textLink,
      'textPreformat.foreground': customColors.special.foreground,
      // BUTTON CONTROL
      'button.background': customColors.special.accent,
      'button.foreground': customColors.special.textInverse,
      'button.hoverBackground': customColors.special.accentHover,
      // DROPDOWN CONTROL
      'dropdown.background': customColors.special.surface,
      'dropdown.foreground': customColors.special.textSecondary,
      'dropdown.border': customColors.special.border,
      // INPUT CONTROL
      'input.background': customColors.special.surface,
      'input.border': customColors.special.borderSubtle,
      'input.foreground': customColors.special.foreground,
      'input.placeholderForeground': customColors.special.textDisabled,
      'inputOption.activeBorder': customColors.special.accent,
      'inputValidation.errorBackground': customColors.special.backgroundAlt,
      'inputValidation.errorBorder': customColors.special.error,
      'inputValidation.infoBackground': customColors.special.backgroundAlt,
      'inputValidation.infoBorder': customColors.special.info,
      'inputValidation.warningBackground': customColors.special.backgroundAlt,
      'inputValidation.warningBorder': customColors.special.warning,
      // SCROLLBAR CONTROL
      'scrollbar.shadow': customColors.special.borderSubtle,
      'scrollbarSlider.background': customColors.special.textMuted,
      'scrollbarSlider.hoverBackground': customColors.special.textSecondary,
      'scrollbarSlider.activeBackground': customColors.special.foreground,
      // BADGE
      'badge.background': customColors.special.accent,
      'badge.foreground': customColors.special.textInverse,
      // PROGRESS BAR
      'progressBar.background': customColors.special.accent,
      // LISTS AND TREES
      'list.activeSelectionBackground': customColors.special.selection,
      'list.activeSelectionForeground': customColors.special.foreground,
      'list.focusBackground': customColors.special.selection,
      'list.focusForeground': customColors.special.foreground,
      'list.highlightForeground': customColors.special.accent,
      'list.hoverBackground': customColors.special.surfaceHover,
      'list.hoverForeground': customColors.special.foreground,
      'list.inactiveSelectionBackground': customColors.special.highlight,
      'list.inactiveSelectionForeground': customColors.special.foreground,
      'list.invalidItemForeground': customColors.special.textDisabled,
      // ACTIVITY BAR
      'activityBar.background': customColors.special.backgroundAlt,
      'activityBar.foreground': customColors.special.foreground,
      'activityBar.border': bordered ? customColors.special.border : customColors.special.backgroundAlt,
      'activityBarBadge.background': customColors.special.accent,
      'activityBarBadge.foreground': customColors.special.textInverse,
      // SIDE BAR
      'sideBar.background': customColors.special.backgroundAlt,
      'sideBar.border': bordered ? customColors.special.border : customColors.special.backgroundAlt,
      'sideBarTitle.foreground': customColors.special.textSecondary,
      'sideBarSectionHeader.background': customColors.special.backgroundAlt,
      'sideBarSectionHeader.foreground': customColors.special.textSecondary,
      // EDITOR GROUPS & TABS
      'editorGroup.border': customColors.special.border,
      // 'editorGroup.background': colors[0].lighten(0.20).hex(), // deprecated
      'editorGroupHeader.noTabsBackground': customColors.special.backgroundAlt,
      'editorGroupHeader.tabsBackground': customColors.special.backgroundAlt,
      'editorGroupHeader.tabsBorder': bordered ? customColors.special.border : customColors.special.backgroundAlt,
      'tab.activeBackground': bordered ? customColors.special.surface : customColors.special.background,
      'tab.activeForeground': customColors.special.foreground,
      'tab.border': bordered ? customColors.special.border : customColors.special.backgroundAlt,
      'tab.activeBorder': bordered ? undefined : customColors.special.accent,
      'tab.activeBorderTop': bordered ? customColors.special.accent : undefined,
      'tab.unfocusedActiveBorder': bordered ? undefined : customColors.special.textSecondary,
      'tab.unfocusedActiveBorderTop': bordered ? customColors.special.textSecondary : undefined,
      'tab.inactiveBackground': customColors.special.backgroundAlt,
      'tab.inactiveForeground': customColors.special.textSecondary,
      'tab.unfocusedActiveForeground': customColors.special.textSecondary,
      'tab.unfocusedInactiveForeground': customColors.special.textSecondary,
      // EDITOR
      'editor.background': customColors.special.background,
      'editor.foreground': customColors.special.foreground,
      'editorLineNumber.foreground': customColors.special.textDisabled,
      'editorLineNumber.activeForeground': customColors.special.textMuted,
      'editorCursor.foreground': customColors.special.cursor,
      'editor.selectionBackground': customColors.special.selection,
      'editor.inactiveSelectionBackground': customColors.special.highlight,
      'editor.selectionHighlightBackground': customColors.special.highlight,
      'editor.selectionHighlightBorder': customColors.special.border,
      'editor.wordHighlightBackground': customColors.special.highlight,
      'editor.wordHighlightStrongBackground': customColors.special.accentSubtle,
      'editor.findMatchBackground': customColors.special.accentSubtle,
      'editor.findMatchBorder': customColors.special.accent,
      'editor.findMatchHighlightBackground': customColors.special.accentSubtle,
      'editor.findMatchHighlightBorder': customColors.special.accent,
      'editor.findRangeHighlightBackground': customColors.special.highlight,
      'editor.findRangeHighlightBorder': customColors.special.backgroundAlt,
      // 'editor.hoverHighlightBackground': '',
      'editor.lineHighlightBackground': customColors.special.highlight,
      // 'editor.lineHighlightBorder': '',
      'editorLink.activeForeground': customColors.special.textLink,
      'editor.rangeHighlightBackground': customColors.special.highlight,
      'editorWhitespace.foreground': customColors.special.textDisabled,
      'editorIndentGuide.background': customColors.special.borderSubtle,
      'editorIndentGuide.activeBackground': customColors.special.border,
      'editorRuler.foreground': customColors.special.borderSubtle,
      'editorCodeLens.foreground': customColors.special.textMuted,
      'editorBracketMatch.background': customColors.special.cyan5,
      'editorBracketMatch.border': customColors.special.cyan5,
      // BRACKET MATCHES
      'editorBracketHighlight.foreground1': customColors.special.foreground,
      'editorBracketHighlight.foreground2': customColors.special.foreground,
      'editorBracketHighlight.foreground3': customColors.special.foreground,
      'editorBracketHighlight.foreground4': customColors.special.foreground,
      'editorBracketHighlight.foreground5': customColors.special.foreground,
      'editorBracketHighlight.foreground6': customColors.special.foreground,
      // OVERVIEW RULER
      'editorOverviewRuler.border': customColors.special.border,
      'editorOverviewRuler.modifiedForeground': customColors.special.warning,
      'editorOverviewRuler.addedForeground': customColors.special.success,
      'editorOverviewRuler.deletedForeground': customColors.special.error,
      'editorOverviewRuler.errorForeground': customColors.special.error,
      'editorOverviewRuler.warningForeground': customColors.special.warning,
      // ERRORS AND WARNINGS
      'editorError.foreground': customColors.special.error,
      'editorWarning.foreground': customColors.special.warning,
      // GUTTER
      'editorGutter.modifiedBackground': customColors.special.warning,
      'editorGutter.addedBackground': customColors.special.success,
      'editorGutter.deletedBackground': customColors.special.error,
      // DIFF EDITOR
      'diffEditor.insertedTextBackground': customColors.special.green3,
      'diffEditor.removedTextBackground': customColors.special.red3,
      // EDITOR WIDGET
      'editorWidget.background': customColors.special.overlay,
      'editorSuggestWidget.background': customColors.special.overlay,
      'editorSuggestWidget.border': customColors.special.borderSubtle,
      'editorSuggestWidget.highlightForeground': customColors.special.accent,
      'editorSuggestWidget.selectedBackground': customColors.special.selection,
      'editorHoverWidget.background': customColors.special.overlay,
      'editorHoverWidget.border': customColors.special.borderSubtle,
      // DEBUG EXCEPTION
      'debugExceptionWidget.border': customColors.special.border,
      'debugExceptionWidget.background': customColors.special.overlay,
      // EDITOR MARKER
      'editorMarkerNavigation.background': customColors.special.overlay,
      // PEEK VIEW
      'peekView.border': customColors.special.border,
      'peekViewEditor.background': customColors.special.overlay,
      'peekViewEditor.matchHighlightBackground': customColors.special.accentSubtle,
      'peekViewResult.background': customColors.special.overlay,
      'peekViewResult.fileForeground': customColors.special.textSecondary,
      'peekViewResult.matchHighlightBackground': customColors.special.accentSubtle,
      'peekViewTitle.background': customColors.special.overlay,
      'peekViewTitleDescription.foreground': customColors.special.textSecondary,
      'peekViewTitleLabel.foreground': customColors.special.textSecondary,
      // Merge Conflicts
      // 'merge.currentHeaderBackground': '?',
      // 'merge.currentContentBackground': '?',
      // 'merge.incomingHeaderBackground': '?',
      // 'merge.incomingContentBackground': '?',
      // 'merge.border': '?',
      // 'merge.commonContentBackground': '?',
      // 'merge.commonHeaderBackground': '?',
      // 'editorOverviewRuler.currentContentForeground': '?',
      // 'editorOverviewRuler.incomingContentForeground': '?',
      // 'editorOverviewRuler.commonContentForeground': '?',
      // Panel
      'panel.background': customColors.special.backgroundAlt,
      'panel.border': customColors.special.border,
      'panelTitle.activeBorder': customColors.special.accent,
      'panelTitle.activeForeground': customColors.special.foreground,
      'panelTitle.inactiveForeground': customColors.special.textSecondary,
      // STATUS BAR
      'statusBar.background': customColors.special.backgroundAlt,
      'statusBar.foreground': customColors.special.foreground,
      'statusBar.border': bordered ? customColors.special.border : customColors.special.backgroundAlt,
      'statusBar.debuggingBackground': customColors.special.warning,
      'statusBar.debuggingForeground': customColors.special.textInverse,
      'statusBar.noFolderBackground': customColors.special.surface,
      'statusBarItem.activeBackground': '#00000050',
      'statusBarItem.hoverBackground': '#00000030',
      'statusBarItem.prominentBackground': customColors.special.highlight,
      'statusBarItem.prominentHoverBackground': '#00000030',
      // TITLE BAR
      'titleBar.activeBackground': customColors.special.backgroundAlt,
      'titleBar.activeForeground': customColors.special.foreground,
      'titleBar.inactiveBackground': customColors.special.backgroundAlt,
      'titleBar.inactiveForeground': customColors.special.textSecondary,
      'titleBar.border': bordered ? customColors.special.border : customColors.special.backgroundAlt,
      // MENU BAR
      // 'menubar.selectionForeground': '?',
      // 'menubar.selectionBackground': '?',
      // 'menubar.selectionBorder': '?',
      // 'menu.foreground': '?',
      // 'menu.background': '?',
      // 'menu.selectionForeground': '?',
      // 'menu.selectionBackground': '?',
      // 'menu.selectionBorder': '?',
      // NOTIFICATION
      // 'notificationCenter.border': '?',
      // 'notificationCenterHeader.foreground': '?',
      // 'notificationCenterHeader.background': '?',
      // 'notificationToast.border': '?',
      // 'notifications.foreground': '?',
      // 'notifications.background': '?',
      // 'notifications.border': '?',
      // 'notificationLink.foreground': '?',
      // EXTENSIONS
      'extensionButton.prominentForeground': customColors.special.textInverse,
      'extensionButton.prominentBackground': customColors.special.accent,
      'extensionButton.prominentHoverBackground': customColors.special.accentHover,
      // QUICK PICKER
      'pickerGroup.border': customColors.special.border,
      'pickerGroup.foreground': customColors.special.textMuted,
      // DEBUG
      'debugTokenExpression.value': customColors.special.textMuted,
      'debugToolBar.background': customColors.special.backgroundAlt,
      // 'debugToolBar.border': '',
      // WELCOME PAGE
      // 'welcomePage.buttonBackground': '?'
      // 'welcomePage.buttonHoverBackground': '?'
      'walkThrough.embeddedEditorBackground': customColors.special.surface,
      // GIT
      'gitDecoration.modifiedResourceForeground': customColors.special.warning,
      'gitDecoration.deletedResourceForeground': customColors.special.error,
      'gitDecoration.untrackedResourceForeground': customColors.special.success,
      'gitDecoration.ignoredResourceForeground': customColors.special.textDisabled,
      // 'gitDecoration.conflictingResourceForeground': '?',
      'gitDecoration.submoduleResourceForeground': customColors.special.info,
      // Settings
      'settings.headerForeground': customColors.special.foreground,
      'settings.modifiedItemIndicator': customColors.special.success,
      // TERMINAL
      'terminal.background': customColors.special.background,
      'terminal.foreground': customColors.special.foreground,
      'terminal.ansiBlack': customColors.special.backgroundAlt,
      'terminal.ansiRed': colors[1].hex(),
      'terminal.ansiGreen': colors[2].hex(),
      'terminal.ansiYellow': colors[3].hex(),
      'terminal.ansiBlue': colors[4].hex(),
      'terminal.ansiMagenta': colors[5].hex(),
      'terminal.ansiCyan': colors[6].hex(),
      'terminal.ansiWhite': colors[7].hex(),
      'terminal.ansiBrightBlack': colors[8].hex(),
      'terminal.ansiBrightRed': colors[9].hex(),
      'terminal.ansiBrightGreen': colors[10].hex(),
      'terminal.ansiBrightYellow': colors[11].hex(),
      'terminal.ansiBrightBlue': colors[12].hex(),
      'terminal.ansiBrightMagenta': colors[13].hex(),
      'terminal.ansiBrightCyan': colors[14].hex(),
      'terminal.ansiBrightWhite': colors[15].hex(),
      'debugConsole.infoForeground': customColors.special.info,
      'sideBar.border': customColors.special.border,
      'tab.activeBorder': customColors.special.accent,
      'editor.selectionHighlightBackground': customColors.special.highlight,
      'editor.selectionHighlightBorder': customColors.special.border,
      'editor.wordHighlightBackground': customColors.special.highlight,
      'editor.wordHighlightBorder': customColors.special.border,
      'editorUnnecessaryCode.border': customColors.special.textDisabled,
      'editorUnnecessaryCode.opacity': '#000000'
    },

    'tokenColors': [
      {
        'settings': {
          'background': customColors.special.background,
          'foreground': customColors.special.foreground
        }
      },

      {
        'name': 'Comment',
        'scope': ['comment'],
        'settings': {
          'fontStyle': 'italic',
          'foreground': customColors.special.syntaxComment
        }
      },
      {
        'name': 'Regular Expressions and Escape Characters',
        'scope': ['string.regexp', 'constant.character', 'constant.other'],
        'settings': {
          'foreground': customColors.special.syntaxStringEscape
        }
      },
    
      {
        'name': 'Member Variable',
        'scope': ['variable.member'],
        'settings': {
          'foreground': colors[1].hex()
        }
      },
    
      {
        'name': 'Language variable',
        'scope': ['variable.language'],
        'settings': {
          'fontStyle': 'italic',
          'foreground': colors[2].hex()
        }
      },
    
      {
        'name': 'Inherited class type',
        'scope': ['entity.other.inherited-class'],
        'settings': {
          'foreground': colors[2].hex()
        }
      },
    
      {
        'name': 'Invalid',
        'scope': ['invalid'],
        'settings': {
          'foreground': colors[4].hex()
        }
      },
    
      {
        'name': 'diff.header',
        'scope': ['meta.diff', 'meta.diff.header'],
        'settings': {
          'foreground': colors[13].hex()
        }
      },
    
      {
        'name': 'Ruby class methods',
        'scope': ['source.ruby variable.other.readwrite'],
        'settings': {
          'foreground': colors[11].hex()
        }
      },
    
      {
        'name': 'CSS tag names',
        'scope': [
          'source.css entity.name.tag',
          'source.sass entity.name.tag',
          'source.scss entity.name.tag',
          'source.less entity.name.tag',
          'source.stylus entity.name.tag'
        ],
        'settings': {
          'foreground': colors[12].hex()
        }
      },
    
      {
        'name': 'Markup heading',
        'scope': ['markup.heading', 'markup.heading entity.name'],
        'settings': {
          'fontStyle': 'bold',
          'foreground': colors[10].hex()
        }
      },
    
      {
        'name': 'Markup links',
        'scope': ['markup.underline.link', 'string.other.link'],
        'settings': {
          'foreground': colors[2].hex()
        }
      },
    
      {
        'name': 'Markup Italic',
        'scope': ['markup.italic'],
        'settings': {
          'fontStyle': 'italic',
          'foreground': colors[1].hex()
        }
      },
    
      {
        'name': 'Markup Bold',
        'scope': ['markup.bold'],
        'settings': {
          'fontStyle': 'bold',
          'foreground': colors[1].hex()
        }
      },
    
      {
        'name': 'Markup Bold/italic',
        'scope': ['markup.italic markup.bold', 'markup.bold markup.italic'],
        'settings': {
          'fontStyle': 'bold italic'
        }
      },
    
      {
        'name': 'Markup Code',
        'scope': ['markup.raw'],
        'settings': {
          'background': colors[7].hex() + '06'
        }
      },
    
      {
        'name': 'Markup Code Inline',
        'scope': ['markup.raw.inline'],
        'settings': {
          'background': colors[7].hex() + '10'
        }
      },
    
      {
        'name': 'Markdown Separator',
        'scope': ['meta.separator'],
        'settings': {
          'fontStyle': 'bold',
          'background': colors[7].hex() + '10',
          'foreground': colors[8].hex() + 'b0'
        }
      },
    
      {
        'name': 'Markup Blockquote',
        'scope': ['markup.quote'],
        'settings': {
          'foreground': colors[14].hex(),
          'fontStyle': 'italic'
        }
      },
    
      {
        'name': 'Markup List Bullet',
        'scope': ['markup.list punctuation.definition.list.begin'],
        'settings': {
          'foreground': colors[11].hex()
        }
      },
    
      {
        'name': 'Markup added',
        'scope': ['markup.inserted'],
        'settings': {
          'foreground': colors[2].hex()
        }
      },
    
      {
        'name': 'Markup modified',
        'scope': ['markup.changed'],
        'settings': {
          'foreground': colors[3].hex()
        }
      },
    
      {
        'name': 'Markup removed',
        'scope': ['markup.deleted'],
        'settings': {
          'foreground': colors[4].hex()
        }
      },
    
      {
        'name': 'Markup Strike',
        'scope': ['markup.strike'],
        'settings': {
          'foreground': colors[13].hex()
        }
      },
    
      {
        'name': 'Markup Table',
        'scope': ['markup.table'],
        'settings': {
          'background': colors[7].hex() + '10',
          'foreground': colors[2].hex()
        }
      },
    
      {
        'name': 'Markup Raw Inline',
        'scope': ['text.html.markdown markup.inline.raw'],
        'settings': {
          'foreground': colors[3].hex()
        }
      },
    
      {
        'name': 'Markdown - Line Break',
        'scope': ['text.html.markdown meta.dummy.line-break'],
        'settings': {
          'background': colors[8].hex() + 'b0',
          'foreground': colors[8].hex() + 'b0'
        }
      },
    
      {
        'name': 'Markdown - Raw Block Fenced',
        'scope': ['punctuation.definition.markdown'],
        'settings': {
          'background': colors[7].hex(),
          'foreground': colors[8].hex() + 'b0'
        }
      },
    
      {
        'scope': ['markup.fenced_code', 'markup.inline.raw.string.markdown'],
        'settings': {
          'foreground': colors[4].hex()
        }
      },
    
      {
        'scope': ['entity.name.section.markdown'],
        'settings': {
          'foreground': colors[3].hex()
        }
      },
    
      {
        'name': 'Storage / imports (custom)',
        'scope': [
          'keyword.control',
          'keyword.control.import',
          'keyword.control.export',
          'keyword.control.flow',
          'keyword.declaration',
          'storage.type',
          'storage.modifier',
          'keyword.other.module',
          'meta.import',
          'meta.import.js',
          'meta.import.ts'
        ],
        'settings': { 'foreground': customColors.special.syntaxKeyword }
      },
    
      {
        'name': 'Types / Functions / Decorators (custom)',
        'scope': [
          'entity.name.type',
          'entity.name.type.class',
          'support.type',
          'meta.class',
          'entity.name.function',
          'support.function',
          'meta.function-call',
          'meta.method-call',
          'variable.function',
          'meta.decorator',
          'storage.type.annotation',
          'meta.annotation'
        ],
        'settings': { 'foreground': customColors.special.syntaxFunction }
      },
    
      {
        'name': 'Strings (custom)',
        'scope': ['string', 'string.quoted', 'string.template'],
        'settings': { 'foreground': customColors.special.syntaxString }
      },
    
      {
        'name': 'Numbers and constants (custom)',
        'scope': [
          'constant.numeric',
          'constant.numeric.integer',
          'constant.numeric.float',
          'constant.numeric.hex',
          'variable.other.constant',
          'constant.language'
        ],
        'settings': { 'foreground': customColors.special.syntaxNumber }
      },
    
      {
        'name': 'Variables & operator (custom)',
        'scope': ['variable', 'variable.other', 'identifier', 'keyword.operator'],
        'settings': { 'foreground': customColors.special.syntaxVariable }
      },
    
      {
        'name': 'Punctuation (custom)',
        'scope': [
          'punctuation',
          'punctuation.definition',
          'punctuation.separator',
          'punctuation.separator.key-value',
          'punctuation.accessor',
          'punctuation.definition.property',
          'punctuation.dot',
          'punctuation.separator.period',
          'meta.brace',
          'meta.brackets',
          'meta.delimiter'
        ],
        'settings': { 'foreground': customColors.special.syntaxPunctuation }
      }
    ]
  };
};
//# sourceMappingURL=template.js.map
