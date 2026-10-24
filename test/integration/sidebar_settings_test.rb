require File.expand_path('../../test_helper', __FILE__)

class SidebarSettingsIntegrationTest < Redmine::IntegrationTest
  fixtures :all

  setup do
    # Redmine renders 500 pages in the test env (show_exceptions = :all);
    # raise instead so failures show the real exception and backtrace.
    Rails.application.env_config['action_dispatch.show_exceptions'] = false
  end

  teardown do
    set_config('{"order":[],"renames":{},"hidden":[]}')
  end

  def set_config(json)
    Setting.plugin_redmine_sidebar_settings = {'menu_json' => json}
    RedmineSidebarSettings::MenuApplier.apply!
  end

  def menu_names
    Redmine::MenuManager.map(RedmineSidebarSettings::MENU).menu_items.root.children.map { |c| c.name.to_s }
  end

  test 'admin opens the settings page' do
    log_user('admin', 'admin')
    get '/sidebar_settings'
    assert_response :success
    assert_select 'form#rss-form'
    assert_select 'div.rss-row[data-name=home]'
  end

  test 'logged in non-admin gets forbidden' do
    log_user('jsmith', 'jsmith')
    get '/sidebar_settings'
    assert_response :forbidden
  end

  test 'anonymous is redirected to login' do
    get '/sidebar_settings'
    assert_response :redirect
  end

  test 'core pages render' do
    get '/'
    assert_response :success
    log_user('admin', 'admin')
    get '/'
    assert_response :success
  end

  test 'admin saves config and the menu reflects it' do
    log_user('admin', 'admin')
    post '/sidebar_settings/update', params: {
      menu_json: '{"order":["projects","home"],"renames":{"home":"Старт"},"hidden":["help"]}'
    }
    assert_redirected_to '/sidebar_settings'

    assert_not_includes menu_names, 'help'
    assert_equal 'projects', menu_names.first
    home = Redmine::MenuManager.map(RedmineSidebarSettings::MENU).menu_items.root
                     .children.find { |c| c.name.to_s == 'home' }
    assert_equal 'Старт', home.caption
  end

  test 'hidden item can be restored through the same settings' do
    log_user('admin', 'admin')
    post '/sidebar_settings/update', params: {
      menu_json: '{"order":[],"renames":{},"hidden":["help"]}'
    }
    assert_redirected_to '/sidebar_settings'
    assert_not_includes menu_names, 'help'

    post '/sidebar_settings/update', params: {
      menu_json: '{"order":[],"renames":{},"hidden":[]}'
    }
    assert_redirected_to '/sidebar_settings'
    assert_includes menu_names, 'help'
  end

  test 'invalid config is rejected and stored config stays intact' do
    original = '{"order":["home"],"renames":{},"hidden":[]}'
    set_config(original)
    log_user('admin', 'admin')
    post '/sidebar_settings/update', params: {menu_json: '{]'}
    assert_response :unprocessable_entity
    assert_equal original, Setting.plugin_redmine_sidebar_settings['menu_json']
  end

  test 'broken stored config does not break page rendering' do
    set_config('not json at all')
    log_user('admin', 'admin')
    get '/'
    assert_response :success
  end
end
