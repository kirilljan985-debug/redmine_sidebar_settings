# frozen_string_literal: true

# Administration > "Настройки меню": rename, hide and reorder the items of
# the application, project and top menus, plus ModernLayout's fixed side
# panel links. Display only - routes and pages stay intact.
class SidebarSettingsController < ApplicationController
  layout 'admin'

  before_action :require_admin

  def index
    @groups = build_groups
    @menu_json = RedmineSidebarSettings.menu_json
  end

  def update
    config = RedmineSidebarSettings::Config.parse(params[:menu_json])
    RedmineSidebarSettings.save_menu_config!(config)
    RedmineSidebarSettings::MenuApplier.apply!
    flash[:notice] = l(:rss_menu_saved)
    redirect_to action: 'index'
  rescue RedmineSidebarSettings::ValidationError => e
    flash[:error] = "#{l(:rss_invalid_config)}: #{e.errors.join('; ')}"
    @groups = build_groups
    @menu_json = params[:menu_json].to_s
    render action: 'index', status: :unprocessable_entity
  end

  private

  # All managed areas with their items in the effective order: visible ones
  # as ordered by the config, then hidden ones kept by the stash.
  def build_groups
    config = RedmineSidebarSettings.menu_config
    groups = []
    config['menus'].each_key do |menu|
      groups << {
        :key => menu,
        :title => l(:"rss_group_#{menu}"),
        :items => menu_items(menu, config)
      }
    end
    groups << {
      :key => 'mui_nav',
      :title => l(:rss_group_mui_nav),
      :items => mui_items(config)
    }
    groups
  end

  def menu_items(menu, config)
    root = Redmine::MenuManager.map(menu).menu_items.root
    entries = root.children.map { |item| entry_for(item, false, menu) }
    RedmineSidebarSettings::MenuApplier.hidden_items(menu).each do |_name, item|
      entries << entry_for(item, true, menu)
    end

    order_index = config['menus'][menu]['order'].each_with_index.to_h { |name, i| [name, i] }
    entries.sort_by!.with_index { |entry, i| [order_index[entry[:name]] || Float::INFINITY, i] }
    entries
  end

  # ModernLayout's fixed links are hardcoded in its layout, so the editor
  # works with the known catalog instead of live menu items.
  def mui_items(config)
    applier = RedmineSidebarSettings::MenuApplier
    part = config['mui_nav']
    order_index = part['order'].each_with_index.to_h { |name, i| [name, i] }

    entries = RedmineSidebarSettings::MUI_NAV_ITEMS.map do |name, path, locale_key|
      caption = ::I18n.t(locale_key, :default => name.humanize)
      {
        :name => name,
        :caption => part['renames'][name] || caption,
        :default_caption => caption,
        :url_hint => path,
        :hidden => part['hidden'].include?(name)
      }
    end
    entries.sort_by! { |entry| [order_index[entry[:name]] || Float::INFINITY, entries.index(entry)] }
    entries
  end

  def entry_for(item, hidden, menu)
    applier = RedmineSidebarSettings::MenuApplier
    {
      :name => item.name.to_s,
      :caption => safe_caption(item),
      :default_caption => applier.original_caption(menu, item),
      :url_hint => url_hint(item),
      :hidden => hidden
    }
  end

  def safe_caption(item)
    item.caption.to_s
  rescue StandardError
    item.name.to_s.humanize
  end

  def url_hint(item)
    case item.url
    when Hash then "#{item.url[:controller]}##{item.url[:action]}"
    when String then item.url
    when Symbol then ":#{item.url}"
    else ''
    end
  rescue StandardError
    ''
  end
end
