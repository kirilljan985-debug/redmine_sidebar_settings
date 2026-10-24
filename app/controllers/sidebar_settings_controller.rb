# frozen_string_literal: true

# Administration > "Настройки меню": rename, hide and reorder the items of
# the application menu. Display only - routes and pages stay intact.
class SidebarSettingsController < ApplicationController
  layout 'admin'

  before_action :require_admin

  def index
    @items = build_items_list
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
    @items = build_items_list
    @menu_json = params[:menu_json].to_s
    render action: 'index', status: :unprocessable_entity
  end

  private

  # All items of the managed menu in their effective order: visible ones
  # first as ordered by the config, then hidden ones kept by the stash.
  def build_items_list
    root = Redmine::MenuManager.map(RedmineSidebarSettings::MENU).menu_items.root
    applier = RedmineSidebarSettings::MenuApplier
    config = RedmineSidebarSettings.menu_config

    entries = root.children.map { |item| entry_for(item, false) }
    applier.hidden_items.each { |_name, item| entries << entry_for(item, true) }

    order_index = config['order'].each_with_index.to_h { |name, i| [name, i] }
    entries.sort_by!.with_index do |entry, i|
      [order_index[entry[:name]] || Float::INFINITY, i]
    end
    entries
  end

  def entry_for(item, hidden)
    {
      :name => item.name.to_s,
      :caption => safe_caption(item),
      :default_caption => RedmineSidebarSettings::MenuApplier.original_caption(item),
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
