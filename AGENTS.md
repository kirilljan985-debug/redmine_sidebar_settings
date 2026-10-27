# AGENTS.md — память проекта redmine_sidebar_settings («Настройки меню»)

Правила работы, грабли и статус. Живой план — `PLAN.md`.

## Суть плагина (v2.0)

Управление прикладным меню Redmine (`:top_menu`): переименовать / скрыть /
переставить пункты, включая добавленные чужими плагинами. Серверно, на уровне
`Redmine::MenuManager` — поэтому подхватывается любым layout'ом (ModernLayout
рисует это меню в своей левой панели). Только отображение: маршруты, права,
страницы не трогаются; скрытое возвращается галочкой в тех же настройках.

## Архитектура

- `Config` (lib/.../config.rb) — валидация/нормализация JSON-конфига
  `{order, renames, hidden}`. Чистая логика + юнит-тесты.
- `MenuApplier.apply!` — применяет конфиг к `Redmine::MenuManager.map(:top_menu)`:
  - порядок = сортировка `root.children` (имена из order, остальные после —
    стабильно);
  - переименование = `item.instance_variable_set(:@caption, строка)`; оригинал
    запоминается в `MenuApplier.originals`, снятие переименования возвращает;
  - скрытие = удаление из `root.children` c сохранением item в
    `MenuApplier.stash` (возврат без рестарта той же галочкой).
  - Идемпотентен; вызывается из хука `after_plugins_loaded` (после регистрации
    меню всех плагинов, повторяется на каждом reload в dev) и при сохранении
    в админке.
- Админка: `SidebarSettingsController` (`require_admin`, layout 'admin') —
  строки рендерит СЕРВЕР (class .rss-row, data-name), JS только drag&drop
  (HTML5), стрелки и сериализация в JSON на сабмит.

## Грабли (проверено)

- **Нельзя называть методы контроллера `menu_items`** — ApplicationController
  включает `MenuManager::MenuController`, у которого есть `menu_items` без
  аргументов (Redmine вызывает его при отрисовке/подсветке меню); перекрытие
  = `wrong number of arguments` → 500 на каждой отрисовке. Наш хелпер —
  `menu_entries`. См. также `sort_by!.with_index {}` — блок достаётся
  with_index, сортировка молча не выполняется.
- ModernLayout (github.com/cerqueirav/redmine_modern_layout): левая панель —
  `aside.mui-nav`; верхний блок зашит в layout буквально (управляется только
  DOM-слоем mui_nav), секция «Рабочее пространство» рендерит
  `:application_menu` / `:project_menu` через `menu_items_for` (наши серверные
  правки доходят), список «ПРОЕКТЫ» — `Project.visible.limit(30)`, это не меню.

- Zeitwerk (плагинный lib под eager load): путь файла = константа;
  `ValidationError` — в собственном файле `validation_error.rb`.
- Партиалы хуков — имя файла с подчёркиванием (`_x.html.erb`), иначе
  Missing partial → 500 на каждой странице, и Redmine 7 в тестовой среде
  прячет исключение (`show_exceptions = :all`, DebugExceptions рисует свою
  страницу). Диагностика: кусок `response.body` в сообщении ассерта.
- ERB экранирует `"` внутри `<script type="application/json">` → JSON.parse
  падает → либо `<%= raw ... .to_json %>`, либо дефолты в JS (сейчас строки
  редактора рендерятся сервером, JS не зависит от JSON).
- Propshaft: URL ассетов с дайджестом — в тестах матчить
  `plugin_assets/<id>/name[^"]*\.js`.
- `MenuItem#caption` без аргумента у top_menu: Proc.call(nil) — ок.
- `MenuNode#children` — обычный массив: порядок менять можно напрямую,
  `add_at`/`remove!` поддерживают `parent` и `last_items_count`.
- Multi-worker: MenuManager in-memory — остальные worker'ы применят конфиг
  после рестарта (хук after_plugins_loaded). Задокументировано в README.

## Правила работы

1. Сверять по клону `../redmine-7-source` (7.0-stable), не по памяти.
2. `git status` перед правками; чужое не коммитить.
3. Локально: `ruby -c`, `node --check`, `erb -x` (блочная форма даёт ложную
   ошибку — сверять с ядром); чистая логика — standalone minitest в
   ASCII-каталоге (кириллица в пути ломает require_relative).
4. push с Windows — циклом `for i in {1..6}; do git push && break; sleep 10; done`.
5. «Готово» — только после зелёного CI.

## Статус

- **РЕЛИЗ v2.2.1 (тег v2.2.1), CI зелёный на 7.0-stable и master. Свернулись.**
  Репозиторий: kirilljan985-debug/redmine_sidebar_settings.
  Умеет: три меню ядра (rename/hide/order, drag-n-drop мышкой), свои ссылки в
  верхнем блоке панели ModernLayout (mui_nav.custom — перемещаемые, стабильные
  id), иконка и имя «Настройки меню» в администрировании, JSON-фолбэк.
  Ограничения: иконка своих ссылок — точка (набор иконок ModernLayout зашит в
  нём); multi-worker подхватывает конфиг после рестарта; список «ПРОЕКТЫ»
  панели — не меню.
- История: v1.x сайдбар-движок DOM-правил (удалён, в git-истории), v2.0 pivot
  на MenuManager, v2.1 три меню + mui_nav, v2.2 свои ссылки.
- Если продолжать (идеи): управление `:account_menu`, экспорт/импорт конфига,
  живой предпросмотр, иконки для своих ссылок (патч ModernLayout).
