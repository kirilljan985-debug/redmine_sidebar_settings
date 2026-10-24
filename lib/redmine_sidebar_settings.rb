# frozen_string_literal: true

require 'json'

# Root module of the redmine_sidebar_settings plugin ("Настройки меню").
#
# Manages the Redmine application menu (:top_menu) display: rename, hide and
# reorder menu items. Everything happens server-side inside
# Redmine::MenuManager, so every layout and theme (including ModernLayout)
# renders the configured menu. Routes, permissions and pages are never
# touched: a hidden item stays reachable by its direct URL, and it can be
# restored from the same settings page.
module RedmineSidebarSettings
  # The only menu managed by the plugin.
  MENU = :top_menu

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
