# frozen_string_literal: true

module RedmineSidebarSettings
  # Applies the stored menu configuration right after all plugins have
  # registered their menu items (and re-applies on every code reload), so
  # any layout or theme renders the configured menu.
  class Hooks < Redmine::Hook::ViewListener
    def after_plugins_loaded(context = nil)
      MenuApplier.apply!
    rescue StandardError
      # A broken config or a hostile menu state must never break boot.
    end
  end
end
