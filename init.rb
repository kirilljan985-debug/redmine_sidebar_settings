require 'redmine'
require_relative 'lib/redmine_sidebar_settings'

Redmine::Plugin.register :redmine_sidebar_settings do
  name 'Sidebar Settings'
  author 'Redmine Sidebar Settings contributors'
  description 'Admin-configurable sidebar customization: rename, hide and reorder sidebar sections and links. Display only - functions and URLs are never touched.'
  version '1.0.0'
  url 'https://github.com/kirilljan985-debug/redmine_sidebar_settings'
  requires_redmine version_or_higher: '7.0.0'

  settings default: { 'rules_json' => '[]' }

  menu :admin_menu, :sidebar_settings,
       {controller: 'sidebar_settings', action: 'index'},
       caption: :label_sidebar
end

# Load (via Zeitwerk) and thereby register the view hooks listener.
RedmineSidebarSettings::Hooks
