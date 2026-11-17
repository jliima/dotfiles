// Themer theme for Spotify: patches the row height Your Library's virtual list uses in "Default list" mode, and sets
// the native title bar height to the nav's.
//
// Spotify hard-codes 64px rows there (cover 48px + 2 x 8px padding). user.css makes the rows 52px, and the list
// only scrolls right when its JS uses the same height, so the chunk with that code is rewritten before it runs.
// The `themer-compact-library` class on <html> says the patch took; user.css only shrinks the rows under it, so a
// Spotify update that changes the code leaves the stock 64px rows instead of a broken list.
(function themerCompactLibrary() {
  const FIND = 'LIST_DEFAULT||t?64:32';
  const REPLACE = 'LIST_DEFAULT||t?52:32';
  const chunks = (self.rspackChunkclient_web = self.rspackChunkclient_web || []);

  const patch = (chunk) => {
    const modules = chunk && chunk[1];
    if (!modules) {
      return;
    }
    for (const id of Object.keys(modules)) {
      const src = modules[id].toString();
      if (!src.includes(FIND)) {
        continue;
      }
      try {
        // Factories are method shorthands (`12345(e,t,r){...}`); make them a function expression again.
        modules[id] = new Function('return ' + src.replace(FIND, REPLACE).replace(/^[^(]*/, 'function'))();
        document.documentElement.classList.add('themer-compact-library');
      } catch (err) {
        console.warn('Themer: library row height patch failed', err);
      }
    }
  };

  // Chunks already queued but not yet loaded, then every later one.
  chunks.forEach(patch);
  const push = chunks.push;
  chunks.push = function (...args) {
    args.forEach(patch);
    return push.apply(this, args);
  };
})();

// Spotify draws its "..." menu button natively, centred in a title bar it assumes is 64px (the stock nav height).
// user.css makes the nav 48px, so tell Spotify that height to put the dots level with the back/forward arrows.
(function themerTitlebarHeight() {
  const client = window.Spicetify?.Platform?.ControlMessageAPI?._updateUiClient;
  if (!client) {
    setTimeout(themerTitlebarHeight, 300);
    return;
  }
  client.updateTitlebarHeight({ height: 48 }).catch((err) => console.warn('Themer: titlebar height failed', err));
})();

// The compact header (page scrolled down) has no cover. Copy the page header's cover in front of its play button;
// albums, playlists and artists all use .main-entityHeader-imageContainer, and a page without one gets no cover.
(function themerTopbarCover() {
  let queued = false;
  const sync = () => {
    queued = false;
    const bar = document.querySelector('.main-entityHeader-topbarContent');
    if (!bar) {
      return;
    }
    const src = document.querySelector('.main-entityHeader-imageContainer img')?.src;
    let cover = bar.querySelector('.themer-topbar-cover');
    if (!src) {
      cover?.remove();
      return;
    }
    if (!cover) {
      cover = document.createElement('img');
      cover.className = 'themer-topbar-cover';
      cover.alt = '';
      bar.prepend(cover);
    }
    if (cover.src !== src) {
      cover.src = src;
    }
  };
  new MutationObserver(() => {
    if (!queued) {
      queued = true;
      requestAnimationFrame(sync);
    }
  }).observe(document.documentElement, { childList: true, subtree: true });
})();

// Live restyle: Themer's reload copies new colors.css and user.css into Spotify's xpui folder (`spicetify apply`).
// Spotify reads them only at start, so poll them and swap a changed sheet in place, without reloading the page.
(function themerLiveStyles() {
  const last = {};
  const check = async (link) => {
    // link.href is absolute: the page's own URL changes with the route, so a relative name would point elsewhere.
    const name = link.href.split('?')[0];
    try {
      const text = await (await fetch(name, { cache: 'no-store' })).text();
      if (last[name] !== undefined && last[name] !== text) {
        link.href = `${name}?v=${Date.now()}`;
      }
      last[name] = text;
    } catch (err) {
      // The file is missing for a moment while spicetify rewrites the folder.
    }
  };
  setInterval(() => document.querySelectorAll('link.userCSS').forEach(check), 1000);
})();
