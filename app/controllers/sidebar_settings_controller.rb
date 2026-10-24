# frozen_string_literal: true

# Administration > Sidebar: editor for the display-only sidebar rules.
class SidebarSettingsController < ApplicationController
  layout 'admin'

  before_action :require_admin

  def index
    @rules_json = RedmineSidebarSettings.rules_json
  end

  def update
    rules = RedmineSidebarSettings::Config.parse(params[:rules_json])
    RedmineSidebarSettings.save_rules!(rules)
    flash[:notice] = l(:rss_rules_saved)
    redirect_to action: 'index'
  rescue RedmineSidebarSettings::ValidationError => e
    flash[:error] = "#{l(:rss_invalid_rules)}: #{e.errors.join('; ')}"
    @rules_json = params[:rules_json].to_s
    render action: 'index', status: :unprocessable_entity
  end
end
