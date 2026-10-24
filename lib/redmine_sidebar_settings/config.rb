# frozen_string_literal: true

module RedmineSidebarSettings
  # Normalization and validation of the rule set stored in plugin settings.
  # Pure logic without Rails dependencies, raises ValidationError on bad input.
  module Config
    ACTIONS = %w[rename hide move].freeze
    MAX_RULES = 500
    PAGE_PATTERN = /\A(?:\*|[\w-]+\/\*|[\w-]+\/[\w-]+)\z/

    module_function

    # Parses a JSON string into a normalized rule array.
    def parse(json_string)
      raw = JSON.parse(json_string.to_s)
      unless raw.is_a?(Array)
        raise ValidationError, ['JSON must be an array of rules']
      end

      normalize(raw)
    rescue JSON::ParserError
      raise ValidationError, ['Invalid JSON']
    end

    def normalize(raw)
      errors = []
      rules = []
      raw.each_with_index do |entry, idx|
        rule = normalize_rule(entry)
        if rule
          rules << rule
        else
          errors << "rule #{idx + 1}: invalid or incomplete"
        end
      end
      errors << "too many rules (limit #{MAX_RULES})" if rules.size > MAX_RULES
      raise ValidationError, errors unless errors.empty?

      rules
    end

    def normalize_rule(entry)
      return nil unless entry.is_a?(Hash)

      page = entry['page'].to_s.strip
      action = entry['action'].to_s.strip
      target = normalize_target(entry['target'])
      return nil unless page.match?(PAGE_PATTERN)
      return nil unless ACTIONS.include?(action)
      return nil unless target

      rule = {'page' => page, 'action' => action, 'target' => target}
      case action
      when 'rename'
        value = entry['value'].to_s.strip
        return nil if value.empty? || value.length > 100

        rule['value'] = value
      when 'move'
        index = entry['index']
        return nil unless index.is_a?(Integer) && index >= 0 && index <= 1000

        rule['index'] = index
      end
      rule
    end

    # A target is {"css" => selector} or {"kind" => "section"|"item", ...}.
    # The explicit kind may be omitted when heading/href makes it unambiguous.
    def normalize_target(raw)
      return nil unless raw.is_a?(Hash)

      css = raw['css'].to_s.strip
      unless css.empty?
        return nil if css.length > 200

        return {'css' => css}
      end

      kind = raw['kind'].to_s.strip
      heading = raw['heading'].to_s.strip
      href = raw['href'].to_s.strip
      kind = 'section' if kind.empty? && !heading.empty?
      kind = 'item' if kind.empty? && !href.empty?

      if kind == 'section'
        return nil if heading.empty? || heading.length > 100

        return {'kind' => 'section', 'heading' => heading}
      end
      if kind == 'item'
        return nil if href.empty? || href.length > 200

        return {'kind' => 'item', 'href' => href}
      end
      nil
    end
  end
end
