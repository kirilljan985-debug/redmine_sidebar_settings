# frozen_string_literal: true

module RedmineSidebarSettings
  # Selects the rules applicable to a given page.
  # Pure logic without Rails dependencies.
  module Resolver
    module_function

    # Returns the rules applicable to controller/action, ordered from
    # generic ('*') to module ('controller/*') to exact ('controller/action').
    # Within each group the stored order is preserved.
    def for_page(rules, controller_name, action_name)
      key = "#{controller_name}/#{action_name}"
      groups = [[], [], []]
      rules.each do |rule|
        group = group_of(rule['page'], key)
        groups[group] << rule if group
      end
      groups[0] + groups[1] + groups[2]
    end

    def group_of(page, key)
      return 0 if page == '*'
      return 1 if page.end_with?('/*') && key.start_with?(page[0..-3])
      return 2 if page == key

      nil
    end
  end
end
