/* redmine_sidebar_settings - client engine.
 *
 * Applies server-provided rules (window.RedmineSidebarSettings) to the
 * sidebar DOM: rename / hide / move sections, rename / hide links, plus a
 * CSS-selector escape hatch. Nothing is removed from the DOM; any failure
 * leaves the sidebar fully native. A MutationObserver catches sidebar
 * content added late by other plugins.
 */
(function () {
  'use strict';

  var rules = window.RedmineSidebarSettings;
  if (!rules || !rules.length) { return; }

  var applying = false;

  function norm(value) {
    try {
      var url = new URL(value, window.location.href);
      return url.pathname + url.search;
    } catch (e) {
      return String(value || '');
    }
  }

  /* Replaces the first non-empty text node, keeping icons intact. */
  function renameText(el, value) {
    var walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT, null);
    var node;
    while ((node = walker.nextNode())) {
      if (node.nodeValue.trim()) {
        node.nodeValue = value;
        return;
      }
    }
    el.appendChild(document.createTextNode(value));
  }

  /* A top-level element starts its own block when it is an H3 itself or a
     wrapper (typical for plugin content) whose direct child is an H3. */
  function startsWithHeading(el) {
    return el.tagName === 'H3' || !!el.querySelector(':scope > h3');
  }

  /* Top-level blocks: a self-headed element plus everything up to the next one. */
  function blocks(wrap) {
    var list = [], cur = null;
    Array.prototype.forEach.call(wrap.children, function (el) {
      if (startsWithHeading(el)) {
        cur = [el];
        list.push(cur);
      } else if (cur) {
        cur.push(el);
      } else {
        cur = [el];
        list.push(cur);
      }
    });
    return list;
  }

  /* Heading element of a top-level block: an H3 itself, or a wrapper
     (typical for plugin content) whose direct child is an H3. */
  function sectionHeadingEl(block) {
    var first = block[0];
    if (!first) { return null; }
    if (first.tagName === 'H3') { return first; }
    return first.querySelector(':scope > h3');
  }

  function hideEl(el) {
    el.classList.add('rsb-hidden');
  }

  function matchingAnchors(wrap, hrefPrefix) {
    var wanted = norm(hrefPrefix);
    var out = [];
    Array.prototype.forEach.call(wrap.querySelectorAll('a[href]'), function (a) {
      if (norm(a.getAttribute('href')).indexOf(wanted) === 0) { out.push(a); }
    });
    return out;
  }

  function moveBlock(wrap, list, block, index) {
    list.splice(list.indexOf(block), 1);
    var to = Math.max(0, Math.min(index || 0, list.length));
    list.splice(to, 0, block);
    list.forEach(function (b) {
      b.forEach(function (el) { wrap.appendChild(el); });
    });
  }

  function applyRule(wrap, rule) {
    var target = rule.target || {};

    if (target.css) {
      var el = wrap.querySelector(target.css);
      if (!el) { return; }
      if (rule.action === 'hide') { hideEl(el); }
      if (rule.action === 'rename') { renameText(el, rule.value); }
      return;
    }

    if (target.kind === 'section' || (!target.kind && target.heading)) {
      var wanted = target.heading;
      var list = blocks(wrap);
      for (var i = 0; i < list.length; i++) {
        var hEl = sectionHeadingEl(list[i]);
        if (!hEl || (hEl.textContent || '').trim() !== wanted) { continue; }
        if (rule.action === 'rename') { renameText(hEl, rule.value); }
        else if (rule.action === 'hide') { list[i].forEach(hideEl); }
        else if (rule.action === 'move') { moveBlock(wrap, list, list[i], rule.index); }
        return;
      }
      return;
    }

    if (target.kind === 'item' || (!target.kind && target.href)) {
      if (!target.href) { return; }
      matchingAnchors(wrap, target.href).forEach(function (a) {
        if (rule.action === 'rename') {
          renameText(a, rule.value);
        } else if (rule.action === 'hide') {
          var li = a.closest('li');
          hideEl(li && wrap.contains(li) ? li : a);
        }
      });
    }
  }

  function applyAll() {
    var wrap = document.getElementById('sidebar-wrapper') || document.getElementById('sidebar');
    if (!wrap) { return; }
    applying = true;
    try {
      rules.forEach(function (rule) {
        try { applyRule(wrap, rule); } catch (e) { /* one bad rule must not break the rest */ }
      });
    } finally {
      applying = false;
    }
  }

  function start() {
    applyAll();
    var wrap = document.getElementById('sidebar-wrapper') || document.getElementById('sidebar');
    if (!wrap || typeof MutationObserver === 'undefined') { return; }
    var timer = null;
    new MutationObserver(function () {
      if (applying) { return; }
      clearTimeout(timer);
      timer = setTimeout(applyAll, 150);
    }).observe(wrap, {childList: true});
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start);
  } else {
    start();
  }
})();
