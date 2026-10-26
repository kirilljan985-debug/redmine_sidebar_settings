# frozen_string_literal: true

module RedmineSidebarSettings
  # 1. Applies the stored menu configuration right after all plugins have
  #    registered their menu items (and re-applies on every code reload), so
  #    any layout or theme renders the configured menu.
  # 2. Injects the client-side config for ModernLayout's fixed side panel
  #    links (mui_nav) into every page head.
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_layouts_base_html_head, partial: 'hooks/redmine_sidebar_settings_head'

    def after_plugins_loaded(context = nil)
      MenuApplier.apply!
    rescue StandardError
      # A broken config or a hostile menu state must never break boot.
    end
  end
end
