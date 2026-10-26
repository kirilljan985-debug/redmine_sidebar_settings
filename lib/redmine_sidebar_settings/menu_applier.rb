# frozen_string_literal: true

module RedmineSidebarSettings
  # Applies the stored menu configuration to Redmine::MenuManager.
  #
  # Only the in-memory menu trees are modified: item captions, the order of
  # children and whether an item is rendered at all. Routes, permissions and
  # pages are never touched, so a hidden item remains reachable by its direct
  # URL. Applying is idempotent and safe to call on every boot.
  module MenuApplier
    module_function

    # Hidden items are kept here (per menu, per process) so the same settings
    # page can restore them without a restart. On boot the owning plugins
    # re-create their items anyway, and apply! hides them again as configured.
    def stash
      @stash ||= Hash.new { |hash, menu| hash[menu] = {} }
    end

    # Original (pre-rename) caption values, raw as stored in the item.
    def originals
      @originals ||= Hash.new { |hash, menu| hash[menu] = {} }
    end

    def apply!
      Config::MENUS.each do |menu|
        apply_menu(menu, RedmineSidebarSettings.menu_config['menus'][menu])
      end
      nil
    end

    # Items hidden by the config (name => MenuItem), for the admin UI.
    def hidden_items(menu)
      stash[menu].dup
    end

    # Resolved original caption of an item - what it shows without renames.
    def original_caption(menu, item)
      raw = originals[menu].fetch(item.name.to_s) { item.instance_variable_get(:@caption) }
      resolve_caption(raw, item.name)
    end

    def resolve_caption(raw, name)
      case raw
      when Proc then raw.call.to_s
      when Symbol then ::I18n.t(raw, :default => name.to_s.humanize)
      when String then raw
      else name.to_s.humanize
      end
    end

    def apply_menu(menu, config)
      root = Redmine::MenuManager.map(menu).menu_items.root
      hidden = config['hidden']

      # 1. Return stashed items that are no longer hidden.
      stash[menu].each_key do |name|
        next if hidden.include?(name)

        item = stash[menu].delete(name)
        root.add_at(item, root.children.size - root.last_items_count) if item
      end

      # 2. Hide configured items.
      hidden.each do |name|
        item = root.children.find { |c| c.name.to_s == name }
        next unless item

        root.children.delete(item)
        item.parent = nil
        stash[menu][name] = item
      end

      # 3. Renames (revert the ones removed from the config first).
      originals[menu].keys.dup.each do |name|
        next if config['renames'].key?(name)

        item = find_item(menu, root, name)
        if item
          item.instance_variable_set(:@caption, originals[menu].delete(name))
        else
          originals[menu].delete(name)
        end
      end
      config['renames'].each do |name, caption|
        item = find_item(menu, root, name)
        next unless item

        originals[menu][name] = item.instance_variable_get(:@caption) unless originals[menu].key?(name)
        item.instance_variable_set(:@caption, caption)
      end

      # 4. Order (visible items; names missing from the config keep their
      #    relative order after the configured ones).
      known = config['order'].each_with_index.to_h { |name, i| [name, i] }
      positions = {}
      root.children.each_with_index { |child, i| positions[child.object_id] = i }
      root.children.sort_by! do |child|
        [known[child.name.to_s] || Float::INFINITY, positions[child.object_id]]
      end
      nil
    end

    def find_item(menu, root, name)
      root.children.find { |c| c.name.to_s == name } || stash[menu][name]
    end
  end
end
