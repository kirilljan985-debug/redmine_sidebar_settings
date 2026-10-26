/* redmine_sidebar_settings - ModernLayout fixed side panel links.
 *
 * The top section of ModernLayout's side navigation (aside.mui-nav) is
 * hardcoded in its layout, so MenuManager cannot manage it. This engine
 * applies the mui_nav config (rename / hide / order) to those links,
 * matching them by their stable paths. Display only: the links keep their
 * targets, and hidden items are restored by simply unchecking them in the
 * settings (each page load starts from the server-rendered markup).
 *
 * Runs deferred; the config (window.RedmineSidebarSettingsMui, injected
 * inline before this file) is read lazily inside apply().
 */
(function () {
  'use strict';

  /* Temporary diagnostics: shows exactly what the engine sees and applies. */
  function log(message) {
    try { window.console && console.warn('[sidebar_settings] ' + message); } catch (e) { /* noop */ }
  }

  /* Redmine may be deployed under a subdirectory, so match a configured
     path against the pathname suffix; '/' means the app root. */
  function matches(pathname, path) {
    if (path === '/') { return pathname === ''; }
    return pathname === path || pathname.slice(-path.length) === path;
  }

  var PATHS = {
    home: '/',
    my_page: '/my/page',
    my_issues: '/issues',
    projects: '/projects',
    administration: '/admin'
  };

  function apply() {
    var config = window.RedmineSidebarSettingsMui;
    if (!config) {
      log('no config on the page (mui_nav is empty, or this is an old plugin build)');
      return;
    }

    var aside = document.querySelector('aside.mui-nav');
    if (!aside) {
      log('aside.mui-nav not found (no ModernLayout panel on this page?)');
      return;
    }
    /* The fixed links live in the first section (the one without a title). */
    var section = aside.querySelector('nav.mui-nav-section');
    if (!section) {
      log('nav.mui-nav-section not found inside the panel');
      return;
    }

    var byPath = {};
    Array.prototype.forEach.call(section.querySelectorAll('a.mui-nav-link'), function (a) {
      byPath[a.pathname.replace(/\/+$/, '')] = a;
    });
    log('panel found, fixed links: ' + Object.keys(byPath).length +
        '; config: renames=' + JSON.stringify(config.renames || {}) +
        ', hidden=' + JSON.stringify(config.hidden || []) +
        ', order=' + JSON.stringify(config.order || []));

    function link(name) {
      var path = PATHS[name];
      if (!path) { return null; }
      var found = null;
      Object.keys(byPath).some(function (pathname) {
        if (matches(pathname, path)) { found = byPath[pathname]; return true; }
        return false;
      });
      return found;
    }

    var renames = config.renames || {};
    var appliedRenames = 0;
    Object.keys(renames).forEach(function (name) {
      var a = link(name);
      if (!a) { return; }
      var label = a.querySelector('.mui-label');
      if (label) { label.textContent = renames[name]; }
      a.title = renames[name];
      appliedRenames += 1;
    });

    var hidden = config.hidden || [];
    var appliedHidden = 0;
    hidden.forEach(function (name) {
      var a = link(name);
      if (a) { a.style.display = 'none'; appliedHidden += 1; }
    });

    var order = (config.order || []).filter(function (name) { return link(name); });
    if (order.length) {
      var cursor = null;
      order.forEach(function (name) {
        var a = link(name);
        if (cursor) { cursor.after(a); } else { section.prepend(a); }
        cursor = a;
      });
    }

    var allNamed = Object.keys(renames).concat(hidden);
    var missing = allNamed.filter(function (name) { return !link(name); });
    log('applied: renames ' + appliedRenames + '/' + Object.keys(renames).length +
        ', hidden ' + appliedHidden + '/' + hidden.length +
        ', order ' + order.length +
        (missing.length ? '; UNMATCHED: ' + missing.join(', ') : ''));
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', apply);
  } else {
    apply();
  }
})();
