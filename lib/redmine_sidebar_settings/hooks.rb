# frozen_string_literal: true

module RedmineSidebarSettings
  # Injects the plugin assets and the per-page rule set into <head>.
  # The partial renders nothing when there are no rules for the page.
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_layouts_base_html_head, partial: 'hooks/redmine_sidebar_settings_head'
  end
end
