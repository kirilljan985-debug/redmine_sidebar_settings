/* redmine_sidebar_settings - menu editor: mouse drag-n-drop ordering,
 * caption editing, hide/restore. Rows are rendered server-side; JS only
 * reorders them and serializes into the JSON field on save. */
(function () {
  'use strict';

  var form = document.getElementById('rss-form');
  var rowsEl = document.getElementById('rss-rows');
  var jsonEl = document.getElementById('menu_json');
  if (!form || !rowsEl || !jsonEl) { return; }

  function rows() {
    return Array.prototype.slice.call(rowsEl.querySelectorAll('.rss-row'));
  }

  function moveRow(row, delta) {
    var sibling = delta < 0 ? row.previousElementSibling : row.nextElementSibling;
    if (!sibling) { return; }
    rowsEl.insertBefore(row, delta < 0 ? sibling : sibling.nextElementSibling);
  }

  rowsEl.addEventListener('click', function (e) {
    var row = e.target.closest('.rss-row');
    if (!row) { return; }
    if (e.target.classList.contains('rss-up')) { moveRow(row, -1); }
    if (e.target.classList.contains('rss-down')) { moveRow(row, 1); }
  });

  /* Mouse drag-n-drop */
  var dragged = null;
  rowsEl.addEventListener('dragstart', function (e) {
    dragged = e.target.closest('.rss-row');
    if (dragged) { e.dataTransfer.effectAllowed = 'move'; }
  });
  rowsEl.addEventListener('dragover', function (e) {
    e.preventDefault();
    var over = e.target.closest('.rss-row');
    if (!over || over === dragged) { return; }
    var rect = over.getBoundingClientRect();
    var before = (e.clientY - rect.top) < rect.height / 2;
    rowsEl.insertBefore(dragged, before ? over : over.nextElementSibling);
  });
  rowsEl.addEventListener('drop', function (e) { e.preventDefault(); });
  rowsEl.addEventListener('dragend', function () { dragged = null; });

  rowsEl.addEventListener('change', function (e) {
    if (e.target.classList.contains('rss-hidden')) {
      var row = e.target.closest('.rss-row');
      row.classList.toggle('rss-row-hidden', e.target.checked);
    }
  });

  function collect() {
    var order = [], renames = {}, hidden = [];
    rows().forEach(function (row) {
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

  form.addEventListener('submit', function () {
    jsonEl.value = JSON.stringify(collect());
  });

  /* Keep the editor in sync when the JSON is edited directly. */
  jsonEl.addEventListener('change', function () {
    var config;
    try { config = JSON.parse(jsonEl.value); } catch (e) { return; }
    if (!config || typeof config !== 'object') { return; }

    var byName = {};
    rows().forEach(function (row) { byName[row.dataset.name] = row; });
    (config.order || []).forEach(function (name) {
      if (byName[name]) { rowsEl.appendChild(byName[name]); }
    });
    rows().forEach(function (row) {
      var name = row.dataset.name;
      var caption = row.querySelector('.rss-caption');
      var renamed = config.renames && Object.prototype.hasOwnProperty.call(config.renames, name);
      caption.value = renamed ? config.renames[name] : caption.getAttribute('data-default');
      var isHidden = !!(config.hidden && config.hidden.indexOf(name) !== -1);
      row.querySelector('.rss-hidden').checked = isHidden;
      row.classList.toggle('rss-row-hidden', isHidden);
    });
  });
})();
