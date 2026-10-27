/* redmine_sidebar_settings - menu editor: mouse drag-n-drop ordering,
 * caption editing, hide/restore, and custom links for the ModernLayout
 * panel. Rows are rendered server-side in groups (data-menu per container);
 * JS reorders them and serializes the whole configuration into the JSON
 * field on save. */
(function () {
  'use strict';

  var form = document.getElementById('rss-form');
  var jsonEl = document.getElementById('menu_json');
  var containers = Array.prototype.slice.call(document.querySelectorAll('.rss-rows[data-menu]'));
  if (!form || !jsonEl || !containers.length) { return; }

  function rows(container) {
    return Array.prototype.slice.call(container.querySelectorAll('.rss-row:not(.rss-row-custom)'));
  }

  function customRows(container) {
    return Array.prototype.slice.call(container.querySelectorAll('.rss-row-custom'));
  }

  function moveRow(row, delta) {
    var sibling = delta < 0 ? row.previousElementSibling : row.nextElementSibling;
    if (!sibling) { return; }
    row.parentNode.insertBefore(row, delta < 0 ? sibling : sibling.nextElementSibling);
  }

  function setPlaceholderInputs(row, title, url) {
    row.querySelector('.rss-custom-title').placeholder = title;
    row.querySelector('.rss-custom-url').placeholder = url;
  }

  var addCustomButton = document.getElementById('rss-add-custom');
  var phTitle = addCustomButton ? addCustomButton.dataset.phTitle : '';
  var phUrl = addCustomButton ? addCustomButton.dataset.phUrl : '';

  function buildCustomRow(title, url) {
    var row = document.createElement('div');
    row.className = 'rss-row rss-row-custom';
    row.dataset.custom = '1';

    var handle = document.createElement('span');
    handle.className = 'rss-handle rss-handle-ghost';
    row.appendChild(handle);

    var fields = document.createElement('span');
    fields.className = 'rss-fields';
    var titleInput = document.createElement('input');
    titleInput.type = 'text';
    titleInput.className = 'rss-custom-title';
    titleInput.value = title || '';
    titleInput.placeholder = phTitle;
    var urlInput = document.createElement('input');
    urlInput.type = 'text';
    urlInput.className = 'rss-custom-url';
    urlInput.value = url || '';
    urlInput.placeholder = phUrl;
    fields.appendChild(titleInput);
    fields.appendChild(urlInput);
    row.appendChild(fields);

    var del = document.createElement('button');
    del.type = 'button';
    del.className = 'rss-custom-del';
    del.innerHTML = '&#10005;';
    row.appendChild(del);
    return row;
  }

  containers.forEach(function (container) {
    container.addEventListener('click', function (e) {
      var row = e.target.closest('.rss-row');
      if (!row) { return; }
      if (e.target.classList.contains('rss-up')) { moveRow(row, -1); }
      if (e.target.classList.contains('rss-down')) { moveRow(row, 1); }
      if (e.target.classList.contains('rss-custom-del')) { row.remove(); }
    });

    /* Rows are draggable only while dragging starts from the handle:
       otherwise the browser hijacks mouse actions inside the caption
       inputs (caret jumps to the start, text cannot be selected). */
    container.addEventListener('mousedown', function (e) {
      var row = e.target.closest('.rss-row');
      if (row) { row.draggable = e.target.classList.contains('rss-handle'); }
    });
    container.addEventListener('mouseup', function (e) {
      var row = e.target.closest('.rss-row');
      if (row) { row.draggable = false; }
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
    container.addEventListener('dragend', function (e) {
      var row = e.target.closest('.rss-row');
      if (row) { row.draggable = false; }
      dragged = null;
    });

    container.addEventListener('change', function (e) {
      if (e.target.classList.contains('rss-hidden')) {
        e.target.closest('.rss-row').classList.toggle('rss-row-hidden', e.target.checked);
      }
    });

    /* Place the caret at the end of the caption when the field gets focus. */
    container.addEventListener('focusin', function (e) {
      if (!e.target.classList.contains('rss-caption')) { return; }
      var end = e.target.value.length;
      try { e.target.setSelectionRange(end, end); } catch (err) { /* noop */ }
    });
  });

  if (addCustomButton) {
    addCustomButton.addEventListener('click', function () {
      var muiContainer = document.querySelector('.rss-rows[data-menu=mui_nav]');
      if (muiContainer) { muiContainer.appendChild(buildCustomRow('', '')); }
    });
  }

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
    var part = {order: order, renames: renames, hidden: hidden};
    if (container.dataset.menu === 'mui_nav') {
      part.custom = customRows(container).map(function (row) {
        return {
          title: row.querySelector('.rss-custom-title').value.trim(),
          url: row.querySelector('.rss-custom-url').value.trim()
        };
      }).filter(function (entry) { return entry.title && entry.url; });
    }
    return part;
  }

  form.addEventListener('submit', function () {
    var menus = {}, muiNav = null;
    containers.forEach(function (container) {
      var part = collectPart(container);
      if (container.dataset.menu === 'mui_nav') {
        muiNav = part;
      } else {
        menus[container.dataset.menu] = part;
      }
    });
    jsonEl.value = JSON.stringify({menus: menus, mui_nav: muiNav || {order: [], renames: {}, hidden: [], custom: []}});
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
    if (container.dataset.menu === 'mui_nav') {
      customRows(container).forEach(function (row) { row.remove(); });
      (part.custom || []).forEach(function (entry) {
        container.appendChild(buildCustomRow(entry.title, entry.url));
      });
    }
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
