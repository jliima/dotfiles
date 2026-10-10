# Aphelion

A Themer theme made from the Aphelion color scheme of [elenapan's dotfiles](https://github.com/elenapan/dotfiles)
(`config/colorschemes/aphelion`), kept as an extra option next to Pare.

- Dark first: her background `#101319` is `bg`, `#171b24` (color0) the first surface and `#3A435A` (color8)
  `surface-active`; the text is her foreground `#f4f3ee` with color15 `#DDDBCF` as `text-muted`. Her darker "bright"
  colors (color9 to color14) are the `-dim` steps of the hues.
- Her hues: red `#E34F4F`, orange `#e37e4f`, teal `#69bfce` (cyan), sky blue `#5599E2` (blue) and violet `#956dca`
  (lightened a step to pass the contrast check). She has no yellow, green or magenta, so those three are drawn in the
  lightness and chroma of her others. Her color4 indigo is the ground of selected rows.
- Accent is orange, the color she uses for the active window border; links are blue.
- The light variant turns it round: her foreground is the paper, her background the text, and the hues are darkened to
  read on it. Both variants pass `themer check --theme aphelion`.
- Fonts and shapes are Pare's, so switching colors does not move anything.
- Icons: `Aphelion-Colorful` and `Aphelion-Monochrome` (orange and the grounds) in `Icons/`, each with a `-Light`
  twin, built with `icon-sets build -t aphelion -v both`.

Apply it with `themer apply --theme aphelion` or `themer apply --theme aphelion:light`, and go back with
`themer apply --theme pare`. Change it with `themer edit aphelion`.
