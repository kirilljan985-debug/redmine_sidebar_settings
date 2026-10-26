/* redmine_sidebar_settings - menu editor: mouse drag-n-drop ordering,
 * caption editing, hide/restore. Rows are rendered server-side in groups
 * (data-menu per container); JS reorders them and serializes the whole
 * configuration into the JSON field on save. */
(function () {
  'use strict';

  var form = document.getElementById('rss-form');
  var jsonEl = document.getElementById('menu_json');
  var containers = Array.prototype.slice.call(document.querySelectorAll('.rss-rows[data-menu]'));
  if (!form || !jsonEl || !containers.length) { return; }

  function rows(container) {
    return Array.prototype.slice.call(container.querySelectorAll('.rss-row'));
  }

  function moveRow(row, delta) {
    var sibling = delta < 0 ? row.previousElementSibling : row.nextElementSibling;
    if (!sibling) { return; }
    row.parentNode.insertBefore(row, delta < 0 ? sibling : sibling.nextElementSibling);
  }

  containers.forEach(function (container) {
    container.addEventListener('click', function (e) {
      var row = e.target.closest('.rss-row');
      if (!row) { return; }
      if (e.target.classList.contains('rss-up')) { moveRow(row, -1); }
      if (e.target.classList.contains('rss-down')) { moveRow(row, 1); }
    });

    /* Mouse drag-n-drop */
    var dragged = null;
    container.addEventListener('dragstart', function (e) {
      dragged = e.target.closest('.rss-row');
      if (dragged) { e.dataTransfer.effectAllowed = 'move'; }
    });
    container.addEventListener('dragover', function (e) {
      e.preventDefault();
      var over = e.target.closest('.rss-row');
      if (!over || over === dragged) { return; }
      var rect = over.getBoundingClientRect();
      var before = (e.clientY - rect.top) < rect.height / 2;
      container.insertBefore(dragged, before ? over : over.nextElementSibling);
    });
    container.addEventListener('drop', function (e) { e.preventDefault(); });
    container.addEventListener('dragend', function () { dragged = null; });

    container.addEventListener('change', function (e) {
      if (e.target.classList.contains('rss-hidden')) {
        e.target.closest('.rss-row').classList.toggle('rss-row-hidden', e.target.checked);
      }
    });
  });

  function collectPart(container) {
    var order = [], renames = {}, hidden = [];
    rows(container).forEach(function (row) {
      var name = row.dataset.name;
      var caption = row.querySelector('.rss-caption');
      var value = caption.value.trim();
      order.push(name);
      if (value && value !== caption.getAttribute('data-default')) {
        renames[name] = value;
      }
      if (row.querySelector('.rss-hidden').checked) { hidden.push(name); }
    });
    return {order: order, renames: renames, hidden: hidden};
  }

  function collect() {
    var menus = {}, muiNav = null;
    containers.forEach(function (container) {
      var part = collectPart(container);
      if (container.dataset.menu === 'mui_nav') {
        muiNav = part;
      } else {
        menus[container.dataset.menu] = part;
      }
    });
    return {menus: menus, mui_nav: muiNav || {order: [], renames: {}, hidden: []}};
  }

  form.addEventListener('submit', function () {
    jsonEl.value = JSON.stringify(collect());
  });

  function applyPart(container, part) {
    part = part || {};
    var byName = {};
    rows(container).forEach(function (row) { byName[row.dataset.name] = row; });
    (part.order || []).forEach(function (name) {
      if (byName[name]) { container.appendChild(byName[name]); }
    });
    rows(container).forEach(function (row) {
      var name = row.dataset.name;
      var caption = row.querySelector('.rss-caption');
      var renamed = part.renames && Object.prototype.hasOwnProperty.call(part.renames, name);
      caption.value = renamed ? part.renames[name] : caption.getAttribute('data-default');
      var isHidden = !!(part.hidden && part.hidden.indexOf(name) !== -1);
      row.querySelector('.rss-hidden').checked = isHidden;
      row.classList.toggle('rss-row-hidden', isHidden);
    });
  }

  /* Keep the editor in sync when the JSON is edited directly. */
  jsonEl.addEventListener('change', function () {
    var config;
    try { config = JSON.parse(jsonEl.value); } catch (e) { return; }
    if (!config || typeof config !== 'object') { return; }
    var menus = config.menus || {};
    var legacy = !config.menus && (config.order || config.renames || config.hidden);
    containers.forEach(function (container) {
      var menu = container.dataset.menu;
      if (menu === 'mui_nav') {
        applyPart(container, config.mui_nav);
      } else if (menus[menu]) {
        applyPart(container, menus[menu]);
      } else if (legacy && menu === 'top_menu') {
        applyPart(container, config);
      }
    });
  });
})();
