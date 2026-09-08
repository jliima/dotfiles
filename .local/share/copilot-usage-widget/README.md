# Copilot Usage

KDE Plasma 6 panel widget showing GitHub Copilot premium-request usage and
reset date.

## Install

```bash
./install.sh                    # default profile: ~/.copilot
./install.sh ~/.copilot-work    # a custom COPILOT_HOME instead
```

Then: right-click panel → Add Widgets → search "Copilot Usage" → drag to panel.

## How it works

Reads `<COPILOT_HOME>/config.json` → `copilotTokens`, and calls
`https://api.github.com/copilot_internal/user` — the same undocumented
endpoint the official `copilot` CLI itself uses. That endpoint isn't part of
GitHub's public API and can change without notice.
