# frozen_string_literal: true

require 'json'

# Root module of the redmine_sidebar_settings plugin ("Настройки меню").
#
# Manages the Redmine application menus (:top_menu, :application_menu,
# :project_menu) display: rename, hide and reorder items. Everything happens
# server-side inside Redmine::MenuManager, so every layout and theme -
# including ModernLayout, whose "workspace" section renders :application_menu
# / :project_menu - picks the configuration up automatically. Routes,
# permissions and pages are never touched: a hidden item stays reachable by
# its direct URL and can be restored from the same settings page.
#
# ModernLayout's fixed top links (Home, My page, My issues, Projects,
# Administration) are hardcoded in its layout and cannot be managed through
# MenuManager; they are handled by a small client-side layer (mui_nav).
module RedmineSidebarSettings
  # Fixed links of the ModernLayout side panel (top section), by stable path.
  MUI_NAV_ITEMS = [
    ['home', '/', 'rss_mui_home'],
    ['my_page', '/my', 'rss_mui_my_page'],
    ['my_issues', '/issues', 'rss_mui_my_issues'],
    ['projects', '/projects', 'rss_mui_projects'],
    ['administration', '/admin', 'rss_mui_administration']
  ].freeze

  module_function

  def menu_json
    value = (Setting.plugin_redmine_sidebar_settings || {})['menu_json']
    value.to_s
  end

  # Parsed config; a broken stored config yields the empty one instead of
  # raising - a bad setting must never break menu rendering.
  def menu_config
    Config.parse(menu_json)
  rescue ValidationError
    Config::EMPTY
  end

  def save_menu_config!(normalized)
    Setting.plugin_redmine_sidebar_settings = {'menu_json' => JSON.generate(normalized)}
  end
end
