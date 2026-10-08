[Appearance]
ColorScheme={{ scheme }}
Font={{ fonts.mono }},{{ fonts.mono-size }},-1,5,{{ fonts.mono-weight }},0,0,0,0,0,0,0,0,0,0,1
BoldIntense=false
LineSpacing={{ konsole.line-spacing }}
BorderWhenActive=false
UseFontLineChararacters=false

[Cursor Options]
CursorShape=1
UseCustomCursorColor=true
CustomCursorColor={{ accent | rgb }}
CustomCursorTextColor={{ bg | rgb }}

[General]
Name=Themer
Parent=FALLBACK/
Command=/bin/zsh
DimWhenInactive=false
StartInCurrentSessionDir=false
TerminalColumns=112
TerminalRows=33
TerminalMargin={{ konsole.margin }}
TerminalCenter=false
ShowTerminalSizeHint=false

[Interaction Options]
OpenLinksByDirectClickEnabled=true
TrimLeadingSpacesInSelectedText=false
TrimTrailingSpacesInSelectedText=true
UnderlineFilesEnabled=true

[Scrolling]
HistorySize=10000
ScrollBarPosition=2
ScrollFullPage=false

[Terminal Features]
BlinkingCursorEnabled=true
