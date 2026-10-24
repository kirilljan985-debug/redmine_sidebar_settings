# PLAN.md — живой план

## v1.0 — правила отображения (текущий этап)

- [x] Скелет: init.rb (регистрация, admin_menu «Сайдбар», settings), Zeitwerk-совместимый lib/
- [x] Config: нормализация и валидация правил (page / action / target / value / index)
- [x] Resolver: отбор правил для страницы (* → controller/* → controller/action)
- [x] Хук head: CSS + JS + `window.RedmineSidebarSettings` только при наличии правил
- [x] Движок: rename/hide/move секций, rename/hide ссылок, CSS-escape, MutationObserver
- [x] Админка «Сайдбар»: контроллер (require_admin), редактор правил, JSON-фолбэк
- [x] Тесты: unit (Config, Resolver) + integration (права, сохранение, доставка, отказоустойчивость)
- [x] CI: матрица 7.0-stable/master, sqlite, eager-load smoke check, аннотации ошибок
- [ ] Зелёный CI после первого push

## v1.1 — сканер фактического состава

- [ ] В админке: загрузка страницы-образца в iframe (same-origin), снятие
      секций/ссылок из DOM (`#sidebar-wrapper`)
- [ ] Генерация правил из снимка (переименовать/скрыть/переместить по клику)
- [ ] Ручное добавление правил для пунктов, которых нет на образце
- [ ] Кэш снапшота «что было на странице»

## v2 — идеи

- [ ] Экспорт/импорт конфига
- [ ] Шаблоны наборов правил
- [ ] Учет RTL/тем при необходимости
