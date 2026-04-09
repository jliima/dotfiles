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

Works on my my machine running [Kubuntu 25.10](https://kubuntu.org/)

## Requirements

> [!NOTE]
> This is by no means a complete list at the moment!

### Dotfiles management
[STOW](https://www.gnu.org/software/stow/)

### Appearance

- [Darkly (v0.5.16)](https://github.com/Bali10050/Darkly/releases/tag/v0.5.16)
- [KDE Rounded corners](https://github.com/matinlotfali/KDE-Rounded-Corners)
- [Pywal](https://github.com/eylles/pywal16)
- [Pywalfox](https://github.com/Frewacom/pywalfox)
- [Dark Reader Pywalfox](https://github.com/eylles/pywal16)
- [Walogram](https://codeberg.org/thirtysix/walogram)
- [Intellij Idea](https://github.com/jliima/jetbrains-pywal-theme)

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
