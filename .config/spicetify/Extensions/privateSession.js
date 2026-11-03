// Keeps Spotify's private session on: enabled at startup and renewed before Spotify's 6 h limit ends it.
// Switching it off by hand (Profile menu) keeps it off until the next Spotify restart.
(async function privateSession() {
  const LIMIT_MS = 6 * 60 * 60 * 1000; // Spotify ends a private session after 6 h
  const RENEW_MS = 5 * 60 * 60 * 1000; // renew a bit earlier so it never lapses
  const SLACK_MS = 10 * 60 * 1000; // an "off" this close to the limit is the expiry, not the user
  const SETTLE_MS = 3000; // subscription events of our own renewal arrive late, ignore them this long

  while (!(Spicetify.Platform && Spicetify.Platform.PrivateSessionAPI && Spicetify.Menu)) {
    await new Promise((resolve) => setTimeout(resolve, 300));
  }
  const api = Spicetify.Platform.PrivateSessionAPI;
  let enabledAt = 0;
  let renewTimer = null;
  let renewing = false;

  const item = new Spicetify.Menu.Item("Private session", false, (self) => {
    api.setPrivateSession(!self.isEnabled);
  });
  item.register();

  function scheduleRenew() {
    clearTimeout(renewTimer);
    renewTimer = setTimeout(renew, RENEW_MS);
  }

  // Off and on again starts a fresh 6 h session
  async function renew() {
    renewing = true;
    await api.setPrivateSession(false);
    await api.setPrivateSession(true);
    enabledAt = Date.now();
    scheduleRenew();
    setTimeout(() => (renewing = false), SETTLE_MS);
  }

  api.subscribeToPrivateSession((on) => {
    item.setState(!!on);
    if (renewing) return;
    if (on) {
      enabledAt = Date.now(); // on at startup, or switched back on by hand
      scheduleRenew();
      return;
    }
    clearTimeout(renewTimer);
    if (enabledAt && Date.now() - enabledAt > LIMIT_MS - SLACK_MS) {
      // The session ran out. Set it after the callback, a set from inside it has no effect.
      setTimeout(() => api.setPrivateSession(true), 500);
    } // else: the user switched it off, leave it off
  });

  api.setPrivateSession(true);
})();
