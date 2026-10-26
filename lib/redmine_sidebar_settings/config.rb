# frozen_string_literal: true

module RedmineSidebarSettings
  # Normalization and validation of the menu configuration stored in plugin
  # settings. Pure logic without Rails dependencies, raises ValidationError
  # on bad input.
  #
  # Schema v2:
  # {
  #   "menus": {
  #     "top_menu":        {"order" => [...], "renames" => {...}, "hidden" => [...]},
  #     "application_menu": {...},
  #     "project_menu":     {...}
  #   },
  #   "mui_nav": {...}  # fixed links of the ModernLayout side panel (DOM layer)
  # }
  # A legacy flat config (only the three keys) is treated as top_menu.
  module Config
    NAME_PATTERN = /\A[\w-]+\z/
    MAX_ITEMS = 100
    MAX_CAPTION = 100
    MENUS = %w[top_menu application_menu project_menu].freeze
    SECTIONS = (MENUS + %w[mui_nav]).freeze

    EMPTY_PART = {'order' => [].freeze, 'renames' => {}.freeze, 'hidden' => [].freeze}.freeze
    EMPTY = {'menus' => MENUS.each_with_object({}) { |m, h| h[m] = EMPTY_PART },
             'mui_nav' => EMPTY_PART}.freeze

    module_function

    # Parses a JSON string into a normalized configuration.
    def parse(json_string)
      raw = JSON.parse(json_string.to_s)
      return normalize({}) if raw.is_a?(Array)

      unless raw.is_a?(Hash)
        raise ValidationError, ['JSON must be an object']
      end

      normalize(raw)
    rescue JSON::ParserError
      raise ValidationError, ['Invalid JSON']
    end

    def normalize(raw)
      if raw['menus'].is_a?(Hash) || raw.key?('mui_nav')
        normalize_v2(raw)
      else
        # Legacy flat config: {order, renames, hidden} meant top_menu.
        {'menus' => {MENUS.first => normalize_part(raw)},
         'mui_nav' => normalize_part(nil)}.tap do |config|
          MENUS.drop(1).each { |menu| config['menus'][menu] = normalize_part(nil) }
        end
      end
    end

    def normalize_v2(raw)
      errors = []
      menus_raw = raw['menus'].is_a?(Hash) ? raw['menus'] : {}
      unknown = menus_raw.keys.map(&:to_s) - MENUS
      errors << "unknown menus: #{unknown.join(', ')}" unless unknown.empty?

      menus = {}
      MENUS.each do |menu|
        part = normalize_part(menus_raw[menu])
        errors << "#{menu}: invalid configuration" if part.nil?
        menus[menu] = part
      end

      mui = normalize_part(raw['mui_nav'])
      errors << 'mui_nav: invalid configuration' if mui.nil?

      raise ValidationError, errors unless errors.empty?

      {'menus' => menus, 'mui_nav' => mui}
    end

    # {"order" => [names], "renames" => {name => caption}, "hidden" => [names]}
    def normalize_part(value)
      return EMPTY_PART.dup if value.nil?
      return nil unless value.is_a?(Hash)

      order = normalize_names(value['order'])
      renames = normalize_renames(value['renames'])
      hidden = normalize_names(value['hidden'])
      return nil if order.nil? || renames.nil? || hidden.nil?

      {'order' => order, 'renames' => renames, 'hidden' => hidden}
    end

    def normalize_names(value)
      return [] if value.nil?
      return nil unless value.is_a?(Array)
      return nil if value.size > MAX_ITEMS

      value.map do |name|
        name = name.to_s.strip
        return nil unless name.match?(NAME_PATTERN)

        name
      end.uniq
    end

    def normalize_renames(value)
      return {} if value.nil?
      return nil unless value.is_a?(Hash)
      return nil if value.size > MAX_ITEMS

      renames = {}
      value.each do |name, caption|
        name = name.to_s.strip
        caption = caption.to_s.strip
        return nil unless name.match?(NAME_PATTERN)
        return nil if caption.empty? || caption.length > MAX_CAPTION

        renames[name] = caption
      end
      renames
    end
  end
end
