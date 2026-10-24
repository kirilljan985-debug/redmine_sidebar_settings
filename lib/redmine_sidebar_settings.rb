# frozen_string_literal: true

require 'json'

# Root module of the redmine_sidebar_settings plugin.
#
# The plugin customizes the sidebar display only: rules are resolved
# server-side per page and applied to the DOM by the client engine
# (assets/javascripts/sidebar_settings.js). Nothing is removed from the
# DOM and no links or permissions are touched.
module RedmineSidebarSettings
  # Known sidebar pages with sample URLs (admin UI suggestions).
  PAGE_CATALOG = [
    ['*', '/'],
    ['issues/index', '/issues'],
    ['issues/show', '/issues/1'],
    ['projects/show', '/projects/demo'],
    ['wiki/show', '/projects/demo/wiki'],
    ['activity/index', '/activity'],
    ['news/index', '/news'],
    ['documents/index', '/documents'],
    ['files/index', '/projects/demo/files'],
    ['search/index', '/search'],
    ['calendar/show', '/projects/demo/issues/calendar'],
    ['gantt/show', '/projects/demo/issues/gantt'],
    ['welcome/index', '/']
  ].freeze

  module_function

  def rules_json
    value = (Setting.plugin_redmine_sidebar_settings || {})['rules_json']
    value.to_s
  end

  # Parsed rules; a broken config yields [] instead of raising -
  # a bad setting must never break page rendering.
  def rules
    Config.parse(rules_json)
  rescue ValidationError
    []
  end

  # Rules applicable to the given page, ordered from generic to specific.
  def rules_for(controller_name, action_name)
    Resolver.for_page(rules, controller_name, action_name)
  end

  def save_rules!(normalized_rules)
    Setting.plugin_redmine_sidebar_settings = {'rules_json' => JSON.generate(normalized_rules)}
  end
end
