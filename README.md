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
- [Themer](themer/README.md) (in this repo), Python 3.11+
- [JetBrains Themer](https://github.com/jliima/jetbrains-pywal-theme) (cloned as `~/JetBrainsProjects/jetbrains-themer`)

### Theming

[Themer](themer/README.md) applies the Pare design system to Plasma, Darkly, KWin, Konsole, Kate, GTK 4 and
Firefox:

```bash
cd ~/dotfiles/themer && ./install.sh   # once per machine: links ~/.local/bin/themer and stows
themer apply --theme pare              # or: themer mode toggle
```

My settings, Konsole profile, Firefox snippets and extra targets are in `.config/themer/`. The extra targets run
when the theme or variant changes:

- "JetBrains IDEs" writes the editor scheme, the UI theme plugin and `~/.cache/themer/jetbrains/themer.theme.json`,
  then runs `apply.sh` from [jetbrains-themer](https://github.com/jliima/jetbrains-pywal-theme) (cloned to
  `~/JetBrainsProjects/jetbrains-themer`, branch `master`), which installs a live reload plugin and reloads every
  running JetBrains IDE, dark or light. The GitHub repo is still named `jetbrains-pywal-theme`.

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
