require 'redmine'
require_relative 'lib/redmine_sidebar_settings'

Redmine::Plugin.register :redmine_sidebar_settings do
  name 'Настройки меню'
  author 'Redmine Sidebar Settings contributors'
  description 'Rename, hide and reorder the Redmine application menu items. Display only - functions and pages stay reachable by their URLs, hidden items can be restored from the same settings.'
  version '2.2.0'
  url 'https://github.com/kirilljan985-debug/redmine_sidebar_settings'
  requires_redmine version_or_higher: '7.0.0'

  settings default: { 'menu_json' => '{"order":[],"renames":{},"hidden":[]}' }

  menu :admin_menu, :sidebar_settings,
       {controller: 'sidebar_settings', action: 'index'},
       caption: :label_menu_settings,
       icon: 'settings',
       html: {class: 'icon icon-settings'}
end

# Load (via Zeitwerk) and thereby register the hook that applies the stored
# menu configuration after all plugins have registered their menu items.
RedmineSidebarSettings::Hooks
