/* redmine_sidebar_settings - menu editor: mouse drag-n-drop ordering,
 * caption editing, hide/restore, and custom links for the ModernLayout
 * panel. Rows are rendered server-side in groups (data-menu per container);
 * JS reorders them and serializes the whole configuration into the JSON
 * field on save. In the mui_nav group custom rows participate in the same
 * order as the fixed items (each has a stable id in data-name). */
(function () {
  'use strict';

  var form = document.getElementById('rss-form');
  var jsonEl = document.getElementById('menu_json');
  var containers = Array.prototype.slice.call(document.querySelectorAll('.rss-rows[data-menu]'));
  if (!form || !jsonEl || !containers.length) { return; }

  function allRows(container) {
    return Array.prototype.slice.call(container.querySelectorAll('.rss-row'));
  }

  function fixedRows(container) {
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

  var addCustomButton = document.getElementById('rss-add-custom');
  var phTitle = addCustomButton ? addCustomButton.dataset.phTitle : '';
  var phUrl = addCustomButton ? addCustomButton.dataset.phUrl : '';

  /* Next free cN id within a container (fixed items use other names). */
  function nextCustomId(container) {
    var taken = {};
    allRows(container).forEach(function (row) {
      if (row.dataset.name) { taken[row.dataset.name] = true; }
    });
    var n = 1;
    while (taken['c' + n]) { n += 1; }
    return 'c' + n;
  }

  function buildCustomRow(id, title, url) {
    var row = document.createElement('div');
    row.className = 'rss-row rss-row-custom';
    row.dataset.name = id || '';

    var handle = document.createElement('span');
    handle.className = 'rss-handle';
    handle.title = handleTitle;
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

  var handleTitle = '';
  containers.forEach(function (container) {
    var handle = container.querySelector('.rss-handle');
    if (handle) { handleTitle = handle.title; }

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
      if (muiContainer) {
        muiContainer.appendChild(buildCustomRow(nextCustomId(muiContainer), '', ''));
      }
    });
  }

  function collectPart(container) {
    var part = {order: [], renames: {}, hidden: []};
    var isMui = container.dataset.menu === 'mui_nav';

    if (!isMui) {
      fixedRows(container).forEach(function (row) {
        var name = row.dataset.name;
        var caption = row.querySelector('.rss-caption');
        var value = caption.value.trim();
        part.order.push(name);
        if (value && value !== caption.getAttribute('data-default')) {
          part.renames[name] = value;
        }
        if (row.querySelector('.rss-hidden').checked) { part.hidden.push(name); }
      });
      return part;
    }

    /* mui_nav: fixed items and custom links share one order. */
    allRows(container).forEach(function (row) {
      var name = row.dataset.name;
      if (!name) { return; }
      part.order.push(name);
      if (row.classList.contains('rss-row-custom')) { return; }
      var caption = row.querySelector('.rss-caption');
      var value = caption.value.trim();
      if (value && value !== caption.getAttribute('data-default')) {
        part.renames[name] = value;
      }
      if (row.querySelector('.rss-hidden').checked) { part.hidden.push(name); }
    });
    part.custom = customRows(container).map(function (row) {
      return {
        id: row.dataset.name || nextCustomId(container),
        title: row.querySelector('.rss-custom-title').value.trim(),
        url: row.querySelector('.rss-custom-url').value.trim()
      };
    }).filter(function (entry) { return entry.title && entry.url; });
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
    jsonEl.value = JSON.stringify({
      menus: menus,
      mui_nav: muiNav || {order: [], renames: {}, hidden: [], custom: []}
    });
  });

  function applyPart(container, part) {
    part = part || {};
    var isMui = container.dataset.menu === 'mui_nav';
    var byName = {};
    fixedRows(container).forEach(function (row) { byName[row.dataset.name] = row; });

    if (isMui) {
      customRows(container).forEach(function (row) { row.remove(); });
      (part.custom || []).forEach(function (entry) {
        var row = buildCustomRow(entry.id, entry.title, entry.url);
        container.appendChild(row);
        byName[entry.id] = row;
      });
    }

    /* One shared order for fixed items and custom links. */
    var order = (part.order || []).filter(function (name) { return byName[name]; });
    if (order.length) {
      var cursor = null;
      order.forEach(function (name) {
        var row = byName[name];
        if (cursor) { cursor.after(row); } else { container.prepend(row); }
        cursor = row;
      });
    }

    fixedRows(container).forEach(function (row) {
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
