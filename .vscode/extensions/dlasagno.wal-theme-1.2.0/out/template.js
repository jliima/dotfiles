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

exports.default = (colors, bordered) => {
    // Load custom colors fresh each time theme is generated
    const customColors = loadCustomColors();
    
    return {
    'type': 'dark',
    'colors': {
        // Colour reference https://code.visualstudio.com/docs/getstarted/theme-color-reference
        // CONTRAST COLOURS
        // --
        // BASE COLOURS
        'focusBorder': (customColors && customColors.special.borderFocus) || colors[1].hex() + '77',
        'foreground': (customColors && customColors.special.foreground) || colors[7].hex(),
        'widget.shadow': colors[0].darken(0.25).hex(),
        'selection.background': (customColors && customColors.special.selection) || colors[7].hex() + '77',
        // TEXT COLOURS
        'textBlockQuote.background': (customColors && customColors.special.surface) || colors[0].lighten(0.20).hex(),
        'textLink.foreground': (customColors && customColors.special.textLink) || colors[13].hex(),
        'textLink.activeForeground': (customColors && customColors.special.textLink) || colors[13].hex(),
        'textPreformat.foreground': (customColors && customColors.special.foreground) || colors[7].hex(),
        // BUTTON CONTROL
        'button.background': (customColors && customColors.special.accent) || colors[4].hex(),
        'button.foreground': (customColors && customColors.special.textInverse) || colors[0].hex(),
        'button.hoverBackground': (customColors && customColors.special.accentHover) || colors[4].hex(),
        // DROPDOWN CONTROL
        'dropdown.background': (customColors && customColors.special.surface) || colors[0].lighten(0.20).hex(),
        'dropdown.foreground': (customColors && customColors.special.textSecondary) || colors[7].hex() + '99',
        'dropdown.border': (customColors && customColors.special.border) || colors[8].hex() + '77',
        // INPUT CONTROL
        'input.background': (customColors && customColors.special.surface) || colors[0].lighten(0.20).hex(),
        'input.border': (customColors && customColors.special.borderSubtle) || colors[8].hex() + '55',
        'input.foreground': (customColors && customColors.special.foreground) || colors[7].hex(),
        'input.placeholderForeground': (customColors && customColors.special.textDisabled) || colors[8].hex() + '77',
        'inputOption.activeBorder': (customColors && customColors.special.accent) || colors[1].hex(),
        'inputValidation.errorBackground': (customColors && customColors.special.backgroundAlt) || colors[0].hex(),
        'inputValidation.errorBorder': (customColors && customColors.special.error) || colors[4].hex(),
        'inputValidation.infoBackground': (customColors && customColors.special.backgroundAlt) || colors[0].hex(),
        'inputValidation.infoBorder': (customColors && customColors.special.info) || colors[2].hex(),
        'inputValidation.warningBackground': (customColors && customColors.special.backgroundAlt) || colors[0].hex(),
        'inputValidation.warningBorder': (customColors && customColors.special.warning) || colors[3].hex(),
        // SCROLLBAR CONTROL
        'scrollbar.shadow': (customColors && customColors.special.borderSubtle) || colors[8].hex() + '33',
        'scrollbarSlider.background': (customColors && customColors.special.textMuted) || colors[7].hex() + '44',
        'scrollbarSlider.hoverBackground': (customColors && customColors.special.textSecondary) || colors[7].hex() + '77',
        'scrollbarSlider.activeBackground': (customColors && customColors.special.foreground) || colors[7].hex() + '92',
        // BADGE
        'badge.background': (customColors && customColors.special.accent) || colors[1].hex(),
        'badge.foreground': (customColors && customColors.special.textInverse) || colors[0].hex(),
        // PROGRESS BAR
        'progressBar.background': (customColors && customColors.special.accent) || colors[1].hex(),
        // LISTS AND TREES
        'list.activeSelectionBackground': (customColors && customColors.special.selection) || colors[8].hex() + '33',
        'list.activeSelectionForeground': (customColors && customColors.special.foreground) || colors[7].hex(),
        'list.focusBackground': (customColors && customColors.special.selection) || colors[8].hex() + '33',
        'list.focusForeground': (customColors && customColors.special.foreground) || colors[7].hex(),
        'list.highlightForeground': (customColors && customColors.special.accent) || colors[1].hex(),
        'list.hoverBackground': (customColors && customColors.special.surfaceHover) || colors[8].hex() + '33',
        'list.hoverForeground': (customColors && customColors.special.foreground) || colors[7].hex(),
        'list.inactiveSelectionBackground': (customColors && customColors.special.highlight) || colors[8].hex() + '33',
        'list.inactiveSelectionForeground': (customColors && customColors.special.foreground) || colors[7].hex(),
        'list.invalidItemForeground': (customColors && customColors.special.textDisabled) || colors[7].hex() + '77',
        // ACTIVITY BAR
        'activityBar.background': (customColors && customColors.special.backgroundAlt) || colors[0].hex(),
        'activityBar.foreground': (customColors && customColors.special.foreground) || colors[7].hex(),
        'activityBar.border': bordered ? ((customColors && customColors.special.border) || colors[8].hex() + '33') : ((customColors && customColors.special.backgroundAlt) || colors[0].hex()),
        'activityBarBadge.background': (customColors && customColors.special.accent) || colors[1].hex(),
        'activityBarBadge.foreground': (customColors && customColors.special.textInverse) || colors[0].hex(),
        // SIDE BAR
        'sideBar.background': (customColors && customColors.special.backgroundAlt) || colors[0].hex(),
        'sideBar.border': bordered ? ((customColors && customColors.special.border) || colors[8].hex() + '33') : ((customColors && customColors.special.backgroundAlt) || colors[0].hex()),
        'sideBarTitle.foreground': (customColors && customColors.special.textSecondary) || colors[7].hex() + '99',
        'sideBarSectionHeader.background': (customColors && customColors.special.backgroundAlt) || colors[0].hex(),
        'sideBarSectionHeader.foreground': (customColors && customColors.special.textSecondary) || colors[7].hex() + '99',
        // EDITOR GROUPS & TABS
        'editorGroup.border': (customColors && customColors.special.border) || colors[8].hex() + '33',
        //'editorGroup.background': colors[0].lighten(0.20).hex(), // deprecated
        'editorGroupHeader.noTabsBackground': (customColors && customColors.special.backgroundAlt) || colors[0].hex(),
        'editorGroupHeader.tabsBackground': (customColors && customColors.special.backgroundAlt) || colors[0].hex(),
        'editorGroupHeader.tabsBorder': bordered ? ((customColors && customColors.special.border) || colors[8].hex() + '33') : ((customColors && customColors.special.backgroundAlt) || colors[0].hex()),
        'tab.activeBackground': bordered ? ((customColors && customColors.special.surface) || colors[0].lighten(0.20).hex()) : ((customColors && customColors.special.background) || colors[0].hex()),
        'tab.activeForeground': (customColors && customColors.special.foreground) || colors[7].hex(),
        'tab.border': bordered ? ((customColors && customColors.special.border) || colors[8].hex() + '33') : ((customColors && customColors.special.backgroundAlt) || colors[0].hex()),
        'tab.activeBorder': bordered ? undefined : ((customColors && customColors.special.accent) || colors[1].hex()),
        'tab.activeBorderTop': bordered ? ((customColors && customColors.special.accent) || colors[1].hex()) : undefined,
        'tab.unfocusedActiveBorder': bordered ? undefined : ((customColors && customColors.special.textSecondary) || colors[7].hex() + '99'),
        'tab.unfocusedActiveBorderTop': bordered ? ((customColors && customColors.special.textSecondary) || colors[7].hex() + '99') : undefined,
        'tab.inactiveBackground': (customColors && customColors.special.backgroundAlt) || colors[0].hex(),
        'tab.inactiveForeground': (customColors && customColors.special.textSecondary) || colors[7].hex() + '99',
        'tab.unfocusedActiveForeground': (customColors && customColors.special.textSecondary) || colors[7].hex() + '99',
        'tab.unfocusedInactiveForeground': (customColors && customColors.special.textSecondary) || colors[7].hex() + '99',
        // EDITOR
        'editor.background': (customColors && customColors.special.background) || colors[0].hex(),
        'editor.foreground': (customColors && customColors.special.foreground) || colors[7].hex(),
        'editorLineNumber.foreground': (customColors && customColors.special.textDisabled) || colors[8].hex() + '92',
        'editorLineNumber.activeForeground': (customColors && customColors.special.textMuted) || colors[8].hex(),
        'editorCursor.foreground': (customColors && customColors.special.cursor) || colors[1].hex(),
        'editor.selectionBackground': (customColors && customColors.special.selection) || colors[8].hex() + '77',
        'editor.inactiveSelectionBackground': (customColors && customColors.special.highlight) || colors[8].hex() + '44',
        'editor.selectionHighlightBackground': (customColors && customColors.special.highlight) || colors[8].hex() + '44',
        'editor.selectionHighlightBorder': (customColors && customColors.special.border) || colors[8].hex(),
        'editor.wordHighlightBackground': (customColors && customColors.special.highlight) || colors[8].hex() + '44',
        'editor.wordHighlightStrongBackground': (customColors && customColors.special.accentSubtle) || colors[2].hex() + '77',
        'editor.findMatchBackground': (customColors && customColors.special.accentSubtle) || colors[1].hex() + '0e',
        'editor.findMatchBorder': (customColors && customColors.special.accent) || colors[1].hex(),
        'editor.findMatchHighlightBackground': (customColors && customColors.special.accentSubtle) || colors[1].hex() + '0e',
        'editor.findMatchHighlightBorder': (customColors && customColors.special.accent) || colors[1].hex() + '66',
        'editor.findRangeHighlightBackground': (customColors && customColors.special.highlight) || colors[8].hex() + '44',
        'editor.findRangeHighlightBorder': (customColors && customColors.special.backgroundAlt) || colors[0].hex() + '00',
        // 'editor.hoverHighlightBackground': '',
        'editor.lineHighlightBackground': (customColors && customColors.special.highlight) || colors[7].hex() + '22',
        // 'editor.lineHighlightBorder': '',
        'editorLink.activeForeground': (customColors && customColors.special.textLink) || colors[13].hex(),
        'editor.rangeHighlightBackground': (customColors && customColors.special.highlight) || colors[8].hex() + '33',
        'editorWhitespace.foreground': (customColors && customColors.special.textDisabled) || colors[8].hex() + '66',
        'editorIndentGuide.background': (customColors && customColors.special.borderSubtle) || colors[8].hex() + '44',
        'editorIndentGuide.activeBackground': (customColors && customColors.special.border) || colors[8].hex() + '77',
        'editorRuler.foreground': (customColors && customColors.special.borderSubtle) || colors[8].hex() + '44',
        'editorCodeLens.foreground': (customColors && customColors.special.textMuted) || colors[7].hex() + 'b0',
        'editorBracketMatch.background': (customColors && customColors.special.cyan5) || colors[6].hex() + '33',
        'editorBracketMatch.border': (customColors && customColors.special.cyan5) || colors[6].hex(),
        // BRACKET MATCHES
        'editorBracketHighlight.foreground1': (customColors && customColors.special.foreground) || colors[7].hex(),
        'editorBracketHighlight.foreground2': (customColors && customColors.special.foreground) || colors[7].hex(),
        'editorBracketHighlight.foreground3': (customColors && customColors.special.foreground) || colors[7].hex(),
        'editorBracketHighlight.foreground4': (customColors && customColors.special.foreground) || colors[7].hex(),
        'editorBracketHighlight.foreground5': (customColors && customColors.special.foreground) || colors[7].hex(),
        'editorBracketHighlight.foreground6': (customColors && customColors.special.foreground) || colors[7].hex(),
        // OVERVIEW RULER
        'editorOverviewRuler.border': (customColors && customColors.special.border) || colors[8].hex() + '33',
        'editorOverviewRuler.modifiedForeground': (customColors && customColors.special.warning) || colors[3].hex() + 'bb',
        'editorOverviewRuler.addedForeground': (customColors && customColors.special.success) || colors[2].hex() + 'bb',
        'editorOverviewRuler.deletedForeground': (customColors && customColors.special.error) || colors[1].hex() + 'bb',
        'editorOverviewRuler.errorForeground': (customColors && customColors.special.error) || colors[1].hex(),
        'editorOverviewRuler.warningForeground': (customColors && customColors.special.warning) || colors[3].hex(),
        // ERRORS AND WARNINGS
        'editorError.foreground': (customColors && customColors.special.error) || colors[1].hex(),
        'editorWarning.foreground': (customColors && customColors.special.warning) || colors[3].hex(),
        // GUTTER
        'editorGutter.modifiedBackground': (customColors && customColors.special.warning) || colors[3].hex() + 'bb',
        'editorGutter.addedBackground': (customColors && customColors.special.success) || colors[2].hex() + 'bb',
        'editorGutter.deletedBackground': (customColors && customColors.special.error) || colors[4].hex() + 'bb',
        // DIFF EDITOR
        'diffEditor.insertedTextBackground': (customColors && customColors.special.green3) || colors[10].hex() + '33',
        'diffEditor.removedTextBackground': (customColors && customColors.special.red3) || colors[3].hex() + '33',
        // EDITOR WIDGET
        'editorWidget.background': (customColors && customColors.special.overlay) || colors[0].lighten(0.20).hex(),
        'editorSuggestWidget.background': (customColors && customColors.special.overlay) || colors[0].lighten(0.20).hex(),
        'editorSuggestWidget.border': (customColors && customColors.special.borderSubtle) || colors[8].hex() + '22',
        'editorSuggestWidget.highlightForeground': (customColors && customColors.special.accent) || colors[1].hex(),
        'editorSuggestWidget.selectedBackground': (customColors && customColors.special.selection) || colors[8].hex() + '33',
        'editorHoverWidget.background': (customColors && customColors.special.overlay) || colors[0].lighten(0.20).hex(),
        'editorHoverWidget.border': (customColors && customColors.special.borderSubtle) || colors[8].hex() + '22',
        // DEBUG EXCEPTION
        'debugExceptionWidget.border': (customColors && customColors.special.border) || colors[8].hex() + '33',
        'debugExceptionWidget.background': (customColors && customColors.special.overlay) || colors[0].lighten(0.20).hex(),
        // EDITOR MARKER
        'editorMarkerNavigation.background': (customColors && customColors.special.overlay) || colors[0].lighten(0.20).hex(),
        // PEEK VIEW
        'peekView.border': (customColors && customColors.special.border) || colors[8].hex() + '33',
        'peekViewEditor.background': (customColors && customColors.special.overlay) || colors[0].lighten(0.20).hex(),
        'peekViewEditor.matchHighlightBackground': (customColors && customColors.special.accentSubtle) || colors[1].hex() + '44',
        'peekViewResult.background': (customColors && customColors.special.overlay) || colors[0].lighten(0.20).hex(),
        'peekViewResult.fileForeground': (customColors && customColors.special.textSecondary) || colors[7].hex() + '99',
        'peekViewResult.matchHighlightBackground': (customColors && customColors.special.accentSubtle) || colors[1].hex() + '44',
        'peekViewTitle.background': (customColors && customColors.special.overlay) || colors[0].lighten(0.20).hex(),
        'peekViewTitleDescription.foreground': (customColors && customColors.special.textSecondary) || colors[7].hex() + '99',
        'peekViewTitleLabel.foreground': (customColors && customColors.special.textSecondary) || colors[7].hex() + '99',
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
        'panel.background': (customColors && customColors.special.backgroundAlt) || colors[0].hex(),
        'panel.border': (customColors && customColors.special.border) || colors[8].hex() + '33',
        'panelTitle.activeBorder': (customColors && customColors.special.accent) || colors[1].hex(),
        'panelTitle.activeForeground': (customColors && customColors.special.foreground) || colors[7].hex(),
        'panelTitle.inactiveForeground': (customColors && customColors.special.textSecondary) || colors[7].hex() + '99',
        // STATUS BAR
        'statusBar.background': (customColors && customColors.special.backgroundAlt) || colors[0].hex(),
        'statusBar.foreground': (customColors && customColors.special.foreground) || colors[7].hex(),
        'statusBar.border': bordered ? ((customColors && customColors.special.border) || colors[8].hex() + '33') : ((customColors && customColors.special.backgroundAlt) || colors[0].hex()),
        'statusBar.debuggingBackground': (customColors && customColors.special.warning) || colors[3].hex(),
        'statusBar.debuggingForeground': (customColors && customColors.special.textInverse) || colors[0].hex() + 'dd',
        'statusBar.noFolderBackground': (customColors && customColors.special.surface) || colors[0].lighten(0.20).hex(),
        'statusBarItem.activeBackground': '#00000050',
        'statusBarItem.hoverBackground': '#00000030',
        'statusBarItem.prominentBackground': (customColors && customColors.special.highlight) || colors[8].hex() + '33',
        'statusBarItem.prominentHoverBackground': '#00000030',
        // TITLE BAR
        'titleBar.activeBackground': (customColors && customColors.special.backgroundAlt) || colors[0].hex(),
        'titleBar.activeForeground': (customColors && customColors.special.foreground) || colors[7].hex(),
        'titleBar.inactiveBackground': (customColors && customColors.special.backgroundAlt) || colors[0].hex(),
        'titleBar.inactiveForeground': (customColors && customColors.special.textSecondary) || colors[7].hex(),
        'titleBar.border': bordered ? ((customColors && customColors.special.border) || colors[8].hex() + '33') : ((customColors && customColors.special.backgroundAlt) || colors[0].hex()),
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
        'extensionButton.prominentForeground': (customColors && customColors.special.textInverse) || colors[0].hex(),
        'extensionButton.prominentBackground': (customColors && customColors.special.accent) || colors[1].hex(),
        'extensionButton.prominentHoverBackground': (customColors && customColors.special.accentHover) || colors[1].hex() + 'b3',
        // QUICK PICKER
        'pickerGroup.border': (customColors && customColors.special.border) || colors[8].hex() + '33',
        'pickerGroup.foreground': (customColors && customColors.special.textMuted) || colors[7].hex() + 'b3',
        // DEBUG
        'debugTokenExpression.value': (customColors && customColors.special.textMuted) || colors[7].hex() + 'b3',
        'debugToolBar.background': (customColors && customColors.special.backgroundAlt) || colors[0].hex(),
        // 'debugToolBar.border': '',
        // WELCOME PAGE
        // 'welcomePage.buttonBackground': '?'
        // 'welcomePage.buttonHoverBackground': '?'
        'walkThrough.embeddedEditorBackground': (customColors && customColors.special.surface) || colors[0].lighten(0.20).hex(),
        // GIT
        'gitDecoration.modifiedResourceForeground': (customColors && customColors.special.warning) || colors[3].hex() + 'cc',
        'gitDecoration.deletedResourceForeground': (customColors && customColors.special.error) || colors[4].hex() + 'cc',
        'gitDecoration.untrackedResourceForeground': (customColors && customColors.special.success) || colors[2].hex() + 'cc',
        'gitDecoration.ignoredResourceForeground': (customColors && customColors.special.textDisabled) || colors[7].hex() + '66',
        // 'gitDecoration.conflictingResourceForeground': '?',
        'gitDecoration.submoduleResourceForeground': (customColors && customColors.special.info) || colors[13].hex() + 'b0',
        // Settings
        'settings.headerForeground': (customColors && customColors.special.foreground) || colors[7].hex(),
        'settings.modifiedItemIndicator': (customColors && customColors.special.success) || colors[2].hex(),
        // TERMINAL
        'terminal.background': (customColors && customColors.special.background) || colors[0].hex(),
        'terminal.foreground': (customColors && customColors.special.foreground) || colors[7].hex(),
        'terminal.ansiBlack': (customColors && customColors.special.backgroundAlt) || colors[0].hex(),
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

        'debugConsole.infoForeground': (customColors && customColors.special.info) || colors[12].hex(),
        'sideBar.border': (customColors && customColors.special.border) || colors[8].hex(),
        'tab.activeBorder': (customColors && customColors.special.accent) || colors[12].hex(),
        'editor.selectionHighlightBackground': (customColors && customColors.special.highlight) || colors[3].hex() + '00',
        'editor.selectionHighlightBorder': (customColors && customColors.special.border) || colors[3].hex(),
        'editor.wordHighlightBackground': (customColors && customColors.special.highlight) || colors[3].hex() + '00',
        'editor.wordHighlightBorder': (customColors && customColors.special.border) || colors[3].hex(),
        'editorUnnecessaryCode.border': (customColors && customColors.special.textDisabled) || colors[8].hex(),
        'editorUnnecessaryCode.opacity': '#000000'
    },
'tokenColors': [
  {
    'settings': {
      'background': (customColors && customColors.special.background) || colors[0].hex(),
      'foreground': (customColors && customColors.special.foreground) || colors[7].hex()
    }
  },

  {
    'name': 'Comment',
    'scope': ['comment'],
    'settings': {
      'fontStyle': 'italic',
      'foreground': (customColors && customColors.special.syntaxComment) || colors[8].hex() + 'b0'
    }
  },

  {
    'name': 'Regular Expressions and Escape Characters',
    'scope': ['string.regexp', 'constant.character', 'constant.other'],
    'settings': {
      'foreground': (customColors && customColors.special.syntaxStringEscape) || colors[14].hex()
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
    'settings': { 'foreground': (customColors && customColors.special.syntaxKeyword) || colors[2].hex() }
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
    'settings': { 'foreground': (customColors && customColors.special.syntaxFunction) || colors[12].hex() }
  },

  {
    'name': 'Strings (custom)',
    'scope': ['string', 'string.quoted', 'string.template'],
    'settings': { 'foreground': (customColors && customColors.special.syntaxString) || colors[13].hex() }
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
    'settings': { 'foreground': (customColors && customColors.special.syntaxNumber) || colors[1].hex() }
  },

  {
    'name': 'Variables & operator (custom)',
    'scope': ['variable', 'variable.other', 'identifier', 'keyword.operator'],
    'settings': { 'foreground': (customColors && customColors.special.syntaxVariable) || colors[15].hex() }
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
    'settings': { 'foreground': (customColors && customColors.special.syntaxPunctuation) || colors[15].hex() }
  }

]

};
};
//# sourceMappingURL=template.js.map
