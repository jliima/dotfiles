<div align="center" markdown="1">
<pre style="font-family: monospace; white-space: pre;">
&nbsp;&nbsp;&nbsp;██████╗&nbsp;&nbsp;██████╗&nbsp;████████╗███████╗██╗██╗&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;███████╗███████╗
&nbsp;&nbsp;&nbsp;██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;██╔════╝██╔════╝
&nbsp;&nbsp;&nbsp;██║&nbsp;&nbsp;██║██║&nbsp;&nbsp;&nbsp;██║&nbsp;&nbsp;&nbsp;██║&nbsp;&nbsp;&nbsp;█████╗&nbsp;&nbsp;██║██║&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;█████╗&nbsp;&nbsp;███████╗
&nbsp;&nbsp;&nbsp;██║&nbsp;&nbsp;██║██║&nbsp;&nbsp;&nbsp;██║&nbsp;&nbsp;&nbsp;██║&nbsp;&nbsp;&nbsp;██╔══╝&nbsp;&nbsp;██║██║&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;██╔══╝&nbsp;&nbsp;╚════██║
██╗██████╔╝╚██████╔╝&nbsp;&nbsp;&nbsp;██║&nbsp;&nbsp;&nbsp;██║&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;██║███████╗███████╗███████║
╚═╝╚═════╝&nbsp;&nbsp;╚═════╝&nbsp;&nbsp;&nbsp;&nbsp;╚═╝&nbsp;&nbsp;&nbsp;╚═╝&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;╚═╝╚══════╝╚══════╝╚══════╝
</pre>
</div>

# Introduction

> [!WARNING]
> Currently work in progress. Can break stuff.

Works on my my machine running [Kubuntu 26.04](https://kubuntu.org/)

## Requirements

> [!NOTE]
> This is by no means a complete list at the moment!

### Dotfiles management
[STOW](https://www.gnu.org/software/stow/)

### Appearance

- [Darkly (v0.5.16)](https://github.com/Bali10050/Darkly/releases/tag/v0.5.16)
- [KDE Rounded corners](https://github.com/matinlotfali/KDE-Rounded-Corners)
- [Themer](https://github.com/jliima/themer), Python 3.11+ (the theming tool, not part of this repo)
- [JetBrains Themer](https://github.com/jliima/jetbrains-pywal-theme) (live reload for JetBrains IDEs, optional; the
  GitHub repo is still named `jetbrains-pywal-theme`)

### Theming

[Themer](https://github.com/jliima/themer) applies the Pare design system to Plasma, Darkly, KWin, Konsole, Kate,
GTK 4 and Firefox. This repo holds only my side of it in `.config/themer/`: settings, the themes (`pare`, `cyan`,
`pink`), the Konsole profile, Firefox snippets and extra targets and templates for apps Themer has no template for.
Themer and the JetBrains plugin are cloned and installed separately, anywhere you like:

```bash
git clone git@github.com:jliima/themer.git ~/Git/themer
~/Git/themer/install.sh --dotfiles ~/dotfiles   # links ~/.local/bin/themer, runs stow
themer apply --theme pare                       # or: themer mode toggle
```

The extra targets run when the theme or variant changes. "JetBrains IDEs" writes the editor scheme, the UI theme
plugin and `~/.cache/themer/jetbrains/themer.theme.json`, then runs `jetbrains-themer-apply` if it is installed:

```bash
git clone git@github.com:jliima/jetbrains-pywal-theme.git ~/Git/jetbrains-themer
~/Git/jetbrains-themer/install.sh               # builds the reload plugin, puts jetbrains-themer-apply on PATH
themer apply --only jetbrains --force
```

The plugin reloads every running JetBrains IDE, dark or light, without a restart.

The KWin decoration is built from a Themer clone: `~/Git/themer/decoration/build.sh`. VS Code gets its themes from a
small extension in the same clone, which reloads the window when a theme changes:

```bash
~/Git/themer/plugins/vscode/install.sh          # add --profile "Name" for every other VS Code profile you use
```

### ZSH & CLI Programs

- [ohmyzsh](https://github.com/ohmyzsh/ohmyzsh)
- [Starship](https://github.com/starship/starship)
- [fzf](https://github.com/junegunn/fzf)
- [zoxide](https://github.com/ajeetdsouza/zoxide)
- [eza](https://github.com/eza-community/eza)
- [tldr](https://github.com/tldr-pages/tldr)

## Apply dotfiles

Clone:

```bash
git clone git@github.com:jliima/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

Apply with stow (example package):

```bash
stow -t "$HOME" <package-name>
```

Re-apply after updates:

```bash
cd ~/dotfiles
git pull
stow -R -t "$HOME" <package-name>
```

Remove links for a package:

```bash
stow -D -t "$HOME" <package-name>
```

Tip: run from `~/dotfiles` and apply only the package(s) you want.
