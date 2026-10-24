# AGENTS.md — память проекта redmine_sidebar_settings

Правила работы, грабли и текущий статус. Живой план — в `PLAN.md`.

## Суть плагина

Display-only настройка сайдбара Redmine 7+: переименовать / скрыть / переставить
секции и ссылки, включая пункты чужих плагинов. Ничего не удалять из DOM, не
трогать href и права. Настройка — только в Администрировании (пункт «Сайдбар»),
никаких живых редакторов на страницах.

## Архитектура (не ломать без нужды)

- `lib/redmine_sidebar_settings/` — чистая логика без Rails: `Config`
  (валидация/нормализация), `Resolver` (отбор правил для страницы: `*` →
  `controller/*` → `controller/action`). Юнит-тесты без Redmine.
- Хук `view_layouts_base_html_head` (партиал
  `app/views/hooks/redmine_sidebar_settings_head.html.erb`) отдаёт CSS+JS и
  `window.RedmineSidebarSettings` ТОЛЬКО когда для страницы есть правила.
- `assets/javascripts/sidebar_settings.js` — движок: rename/hide/move секций
  (блоки = h3 + контент до следующего h3), rename/hide ссылок (матч по
  нормализованному path+query, префикс), CSS-escape hatch. MutationObserver
  (debounce 150ms, флаг `applying`) — для контента чужих плагинов.
- Любая ошибка = нативный сайдбар. Битый JSON → `RedmineSidebarSettings.rules`
  возвращает `[]` (покрыто интеграционным тестом).

## Грабли (проверено по исходникам 7.0-stable)

- `lib/` плагина под Zeitwerk eager load: путь файла обязан совпадать с
  константой. Тестовая среда eager не делает — smoke check обязателен в CI
  (`.github/workflows/test.yml`, шаг «Eager-load smoke check»).
- В Redmine 7 `#sidebar` всегда в DOM; `#main` получает `collapsiblesidebar` /
  `nosidebar`; нативный тумблер запоминает состояние в localStorage по паре
  controller/action (`application-legacy.js`, `$.fn.collapsibleSidebar`).
  Мы это НЕ трогаем.
- `body` получает классы `controller-*`, `action-*`, `project-*` — можно
  адресовать страницы CSS-ом.
- Хуки регистрируются автоматически при наследовании от
  `Redmine::Hook::ViewListener`; в `init.rb` стоит явная ссылка
  `RedmineSidebarSettings::Hooks`, чтобы класс загрузился при старте.
- Ассеты: `stylesheet_link_tag 'x', plugin: 'redmine_sidebar_settings'` →
  `plugin_assets/redmine_sidebar_settings/x`.
- Переопределений вью ядра нет и не надо (GPL + хрупкость). Только хуки.

## Правила работы

1. Всё сверять по клону `../redmine-7-source` (7.0-stable), не по памяти.
2. Перед правками смотреть `git status` — чужие незакоммиченные файлы не
   трогать и не коммитить.
3. Локально: `ruby -c` для .rb, `node --check` для .js, `erb -x -T- файл |
   ruby -c` для .erb (блочная форма `<%= tag ... do %>` даёт ложную ошибку —
   сверять с ядром). Авторитетная среда — CI.
4. push с Windows — циклом `for i in {1..6}; do git push && break; sleep 10; done`.
5. Отчёт «готово» — только после зелёного CI.

## Статус

- v1.0 (в работе): скелет, конфиг/резолвер, движок, админ-редактор правил,
  тесты, CI. Репозиторий: kirilljan985-debug/redmine_sidebar_settings.
- v1.1 (план): iframe-сканер сайдбара в админке (снимок фактического состава
  со страницы-образца, включая чужие плагины) + генерация правил из снимка.
- v2 (идеи): экспорт/импорт конфига; шаблоны правил.
