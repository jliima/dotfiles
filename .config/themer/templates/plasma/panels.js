// Rendered by Themer (target "Plasma panel fonts"). Sizes in the panels that follow the UI font, so they grow with the
// screen profile: the clock's time at 1.1x the UI font, like the usage and CPU numbers next to it. kde-sync leaves
// these keys out of panels.json and runs this again after it rebuilds the panels.
panels().forEach(function (p) {
  p.widgets("org.kde.plasma.digitalclock").forEach(function (w) {
    w.currentConfigGroup = ["Appearance"];
    w.writeConfig("fontSize", Math.round({{ fonts.ui-size }} * 1.1));
  });
});
