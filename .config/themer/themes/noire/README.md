# Noire

A Themer theme drawn from the GMK Noire keycap set (Apiary, with Nephlock on the novelties) and its deskmats.

- Dark first: the grounds are the deskmat's ink black (`bg-deep` #050706, with the faint green it has) rising in small
  steps, the text is its beige (`text` #e5dac6). The light variant swaps them like the beige novelty keys: the mat's
  beige is `bg-deep`, paper-like creams sit above it and the black is `text-bright`.
- Accent is brass (`yellow`, #e7c869 dark, #76611b light), which is also the color of links and the focus ring.
- The other hues are muted and earthy so the screen stays black and beige: terracotta red, copper orange, sage green,
  verdigris cyan, slate blue, mauve violet and dusty rose magenta. All pass the same checks as Pare
  (`themer check --theme noire`).
- Fonts and shapes are Pare's, so switching colors does not move anything.

Apply it with `themer apply --theme noire` or `themer apply --theme noire:light`. Change it with `themer edit noire`.

The matching wallpapers are in `wallpapers/noire` (`noire-<design>_noire.png`, `_noire-light.png`), drawn by
`noire-wallpapers.py`.
