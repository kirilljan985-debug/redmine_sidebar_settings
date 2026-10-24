/* redmine_sidebar_settings - admin rule editor.
 * Renders one row per rule, keeps the hidden/visible JSON field in sync.
 * Without JS the raw JSON textarea remains fully usable. */
(function () {
  'use strict';

  var form = document.getElementById('rss-form');
  var rowsEl = document.getElementById('rss-rows');
  var jsonEl = document.getElementById('rules_json');
  var i18nEl = document.getElementById('rss-i18n');
  var addBtn = document.getElementById('rss-add');
  if (!form || !rowsEl || !jsonEl || !i18nEl || !addBtn) { return; }

  /* English defaults keep the editor working even if the i18n payload
     cannot be parsed; server labels override them below. */
  var T = {
    page: 'Page', action: 'Action', kind: 'Target',
    section: 'Section heading', item: 'Link', css: 'CSS selector',
    target_section: 'Section heading (exact text)', target_item: 'Link path or prefix',
    target_css: 'CSS selector', rename: 'Rename', hide: 'Hide', move: 'Move',
    value: 'New title', index: 'Position (0 = first)',
    up: 'Move rule up', down: 'Move rule down', remove: 'Delete rule'
  };
  try {
    var labels = JSON.parse(i18nEl.textContent);
    for (var key in labels) {
      if (Object.prototype.hasOwnProperty.call(labels, key)) { T[key] = labels[key]; }
    }
  } catch (e) { /* fall back to the defaults above */ }

  var ACTIONS = [['rename', T.rename], ['hide', T.hide], ['move', T.move]];
  var KINDS = [['section', T.section], ['item', T.item], ['css', T.css]];

  function el(tag, className) {
    var node = document.createElement(tag);
    if (className) { node.className = className; }
    return node;
  }

  function input(className, value, placeholder, type) {
    var node = el('input', className);
    node.type = type || 'text';
    node.value = value === undefined || value === null ? '' : value;
    if (placeholder) { node.placeholder = placeholder; }
    return node;
  }

  function select(className, options, value) {
    var node = el('select', className);
    options.forEach(function (o) {
      var opt = document.createElement('option');
      opt.value = o[0];
      opt.textContent = o[1];
      if (o[0] === value) { opt.selected = true; }
      node.appendChild(opt);
    });
    return node;
  }

  function button(className, text, title) {
    var node = el('button', className);
    node.type = 'button';
    node.textContent = text;
    node.title = title;
    return node;
  }

  function targetKind(target) {
    if (!target) { return 'item'; }
    if (target.css) { return 'css'; }
    return target.kind || 'item';
  }

  function targetValue(target) {
    if (!target) { return ''; }
    return target.css || target.heading || target.href || '';
  }

  function updateVisibility(row) {
    var action = row.querySelector('.rss-action').value;
    var kind = row.querySelector('.rss-kind').value;
    row.querySelector('.rss-value').style.display = action === 'rename' ? '' : 'none';
    row.querySelector('.rss-index').style.display = action === 'move' ? '' : 'none';
    row.querySelector('.rss-target').placeholder =
      kind === 'css' ? T.target_css : (kind === 'section' ? T.target_section : T.target_item);
  }

  function moveRow(row, delta) {
    var sibling = delta < 0 ? row.previousElementSibling : row.nextElementSibling;
    if (!sibling) { return; }
    rowsEl.insertBefore(row, delta < 0 ? sibling : sibling.nextElementSibling);
  }

  function renderRow(rule) {
    rule = rule || {};
    var row = el('div', 'rss-row');

    var page = input('rss-page', rule.page || '', T.page);
    page.setAttribute('list', 'rss-pages');
    row.appendChild(page);

    var action = select('rss-action', ACTIONS, rule.action || 'hide');
    row.appendChild(action);

    var kind = select('rss-kind', KINDS, targetKind(rule.target));
    row.appendChild(kind);

    var target = input('rss-target', targetValue(rule.target), T.target_item);
    row.appendChild(target);

    var value = input('rss-value', rule.value, T.value);
    row.appendChild(value);

    var index = input('rss-index', rule.index !== undefined ? rule.index : 0, T.index, 'number');
    index.min = '0';
    row.appendChild(index);

    row.appendChild(button('rss-up', '\u2191', T.up));
    row.appendChild(button('rss-down', '\u2193', T.down));
    row.appendChild(button('rss-del', '\u2715', T.remove));

    row.addEventListener('click', function (e) {
      if (e.target.classList.contains('rss-up')) { moveRow(row, -1); }
      if (e.target.classList.contains('rss-down')) { moveRow(row, 1); }
      if (e.target.classList.contains('rss-del')) { row.remove(); }
    });
    row.addEventListener('change', function () { updateVisibility(row); });

    updateVisibility(row);
    return row;
  }

  function collect() {
    var out = [];
    rowsEl.querySelectorAll('.rss-row').forEach(function (row) {
      var page = row.querySelector('.rss-page').value.trim();
      var target = row.querySelector('.rss-target').value.trim();
      if (!page || !target) { return; }
      var action = row.querySelector('.rss-action').value;
      var kind = row.querySelector('.rss-kind').value;
      var t = {};
      if (kind === 'css') {
        t.css = target;
      } else {
        t.kind = kind;
        if (kind === 'section') { t.heading = target; } else { t.href = target; }
      }
      var rule = {page: page, action: action, target: t};
      if (action === 'rename') { rule.value = row.querySelector('.rss-value').value.trim(); }
      if (action === 'move') { rule.index = parseInt(row.querySelector('.rss-index').value, 10) || 0; }
      out.push(rule);
    });
    return out;
  }

  function renderAll(rules) {
    rowsEl.innerHTML = '';
    (rules || []).forEach(function (rule) { rowsEl.appendChild(renderRow(rule)); });
  }

  addBtn.addEventListener('click', function () {
    rowsEl.appendChild(renderRow({}));
  });

  jsonEl.addEventListener('change', function () {
    try {
      var parsed = JSON.parse(jsonEl.value);
      if (Array.isArray(parsed)) { renderAll(parsed); }
    } catch (e) { /* leave the rows as they are; server validates on save */ }
  });

  form.addEventListener('submit', function () {
    jsonEl.value = JSON.stringify(collect());
  });

  var initial = [];
  try {
    var parsed = JSON.parse(jsonEl.value);
    if (Array.isArray(parsed)) { initial = parsed; }
  } catch (e) { /* server shows the error flash in this case */ }
  renderAll(initial);
})();
