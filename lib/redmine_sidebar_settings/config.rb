# frozen_string_literal: true

module RedmineSidebarSettings
  # Normalization and validation of the menu configuration stored in plugin
  # settings. Pure logic without Rails dependencies, raises ValidationError
  # on bad input.
  module Config
    NAME_PATTERN = /\A[\w-]+\z/
    MAX_ITEMS = 100
    MAX_CAPTION = 100

    EMPTY = {'order' => [].freeze, 'renames' => {}.freeze, 'hidden' => [].freeze}.freeze

    module_function

    # Parses a JSON string into a normalized configuration:
    # {"order" => [names], "renames" => {name => caption}, "hidden" => [names]}
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
      errors = []
      order = normalize_names(raw['order'], 'order')
      renames = normalize_renames(raw['renames'])
      hidden = normalize_names(raw['hidden'], 'hidden')

      errors << 'order must be an array of item names' if order.nil?
      errors << 'renames must be an object of item name => caption' if renames.nil?
      errors << 'hidden must be an array of item names' if hidden.nil?
      raise ValidationError, errors unless errors.empty?

      {'order' => order, 'renames' => renames, 'hidden' => hidden}
    end

    def normalize_names(value, key)
      return [] if value.nil?
      return nil unless value.is_a?(Array)
      return nil if value.size > MAX_ITEMS

      names = value.map do |name|
        name = name.to_s.strip
        return nil unless name.match?(NAME_PATTERN)

        name
      end.uniq
      names
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
