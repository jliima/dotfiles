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

Works on my machine running [Kubuntu 26.04](https://kubuntu.org/)

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

Firefox: Themer writes `userChrome.css` and `userContent.css` into `<profile>/chrome`. I keep one real folder,
`~/.mozilla/firefox/chrome`, and link each profile's `chrome` to it (`ln -s ../chrome ~/.mozilla/firefox/<profile>/chrome`).

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

The repository root is one [stow](https://www.gnu.org/software/stow/) package, so there is no package name:

```bash
git clone git@github.com:jliima/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow --no-folding .          # links everything into $HOME; --no-folding links files, not whole folders
```

Re-apply after updates:

```bash
cd ~/dotfiles
git pull
stow --no-folding -R .
```

Remove the links: `stow -D .`. What must not be linked (this README, `.git`, ...) is listed in `.stow-local-ignore`.

### Between machines

Files that apps rewrite all the time (Kate's `katerc`, the global shortcuts, the Plasma panels) are not stowed.
`scripts/kde/kde-sync` syncs them key by key through `.config/kde-sync`, with per machine keys in
`hosts/<hostname>/`; it runs when one of them changes and after every pull. Once per clone:

```bash
git config core.hooksPath .githooks      # after a pull: stow, then kde-sync
git config pull.rebase true
git config rebase.autoStash true
systemctl --user enable --now kde-sync.path themer-screens.service
systemctl --user enable kde-sync.service
```

`themer-screens.service` switches Themer's screen profile when a screen is plugged in or out (larger fonts on the 32"
4K, see `[[profile]]` in `.config/themer/settings.toml`).

Then install Themer and its plugins (see Theming above). The plugins need `npm` (VS Code) and a JDK (JetBrains IDEs)
on the machine that builds them.
