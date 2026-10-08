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

### Theming

[Themer](https://github.com/jliima/themer) is a generic tool that renders a color scheme into Plasma, Darkly, KWin,
Konsole, Kate, GTK 4, Firefox and more. This repo is what I think a good configuration for it looks like, all in
`.config/themer/`: my settings (screen scales, KDE overrides), the templates for every app, extra targets, and my color
schemes in `themes/`. `pare` is the one I like and use; `cyan` and `pink` are playful extras. None of them is built
into Themer.
Themer is cloned and installed separately, anywhere you like, and so are its plugins:

```bash
git clone git@github.com:jliima/themer.git ~/Git/themer
~/Git/themer/install.sh --dotfiles ~/dotfiles   # links ~/.local/bin/themer, runs stow
themer apply --theme pare                       # or: themer mode toggle
```

`install.sh` also installs the plugins of the apps it finds (VS Code and the JetBrains IDEs); the targets ship with
Themer, the templates are in this repo. Re-run `~/Git/themer/plugins/<app>/install.sh` after a `git pull` to rebuild one
(add `--profile "Name"` to the VS Code one for each extra VS Code profile). The KWin window decoration is separate:
`~/Git/themer/decoration/build.sh`.

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
