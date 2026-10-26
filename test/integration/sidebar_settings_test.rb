require File.expand_path('../../test_helper', __FILE__)

class SidebarSettingsIntegrationTest < Redmine::IntegrationTest
  fixtures :all

  setup do
    # Redmine renders 500 pages in the test env (show_exceptions = :all);
    # raise instead so failures show the real exception and backtrace.
    Rails.application.env_config['action_dispatch.show_exceptions'] = false
    Redmine::MenuManager.map(:application_menu) do |menu|
      menu.push :rsb_test_a, {controller: 'welcome'}, :caption => 'Test A'
    end
  end

  teardown do
    set_config('{"menus":{},"mui_nav":{}}')
    mapper = Redmine::MenuManager.map(:application_menu)
    mapper.delete(:rsb_test_a)
    applier = RedmineSidebarSettings::MenuApplier
    applier.stash.delete(:application_menu)
    applier.originals.delete(:application_menu)
  end

  def set_config(json)
    Setting.plugin_redmine_sidebar_settings = {'menu_json' => json}
    RedmineSidebarSettings::MenuApplier.apply!
  end

  def menu_names(menu = :top_menu)
    Redmine::MenuManager.map(menu).menu_items.root.children.map { |c| c.name.to_s }
  end

  test 'admin opens the settings page with all groups' do
    log_user('admin', 'admin')
    get '/sidebar_settings'
    assert_response :success
    assert_select 'form#rss-form'
    assert_select 'div.rss-rows[data-menu=application_menu]'
    assert_select 'div.rss-rows[data-menu=project_menu]'
    assert_select 'div.rss-rows[data-menu=top_menu]'
    assert_select 'div.rss-rows[data-menu=mui_nav]'
    assert_select 'div.rss-rows[data-menu=mui_nav] div.rss-row[data-name=home]'
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

  test 'admin saves config and the menus reflect it' do
    log_user('admin', 'admin')
    post '/sidebar_settings/update', params: {
      menu_json: '{"menus":{' \
                 '"application_menu":{"order":[],"renames":{"rsb_test_a":"Тест А"},"hidden":[]},' \
                 '"top_menu":{"order":["projects","home"],"renames":{"home":"Старт"},"hidden":["help"]}' \
                 '},"mui_nav":{"order":[],"renames":{},"hidden":[]}}'
    }
    assert_redirected_to '/sidebar_settings'

    assert_not_includes menu_names(:top_menu), 'help'
    assert_equal 'projects', menu_names(:top_menu).first
    home = Redmine::MenuManager.map(:top_menu).menu_items.root
                   .children.find { |c| c.name.to_s == 'home' }
    assert_equal 'Старт', home.caption

    assert_includes menu_names(:application_menu), 'rsb_test_a'
    test_item = Redmine::MenuManager.map(:application_menu).menu_items.root
                              .children.find { |c| c.name.to_s == 'rsb_test_a' }
    assert_equal 'Тест А', test_item.caption
  end

  test 'hidden item can be restored through the same settings' do
    log_user('admin', 'admin')
    post '/sidebar_settings/update', params: {
      menu_json: '{"menus":{"application_menu":{"order":[],"renames":{},"hidden":["rsb_test_a"]}},"mui_nav":{}}'
    }
    assert_redirected_to '/sidebar_settings'
    assert_not_includes menu_names(:application_menu), 'rsb_test_a'

    post '/sidebar_settings/update', params: {
      menu_json: '{"menus":{"application_menu":{"order":[],"renames":{},"hidden":[]}},"mui_nav":{}}'
    }
    assert_redirected_to '/sidebar_settings'
    assert_includes menu_names(:application_menu), 'rsb_test_a'
  end

  test 'invalid config is rejected and stored config stays intact' do
    original = '{"menus":{"top_menu":{"order":["home"],"renames":{},"hidden":[]}},"mui_nav":{}}'
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

  test 'mui_nav config is injected for the ModernLayout panel' do
    set_config('{"menus":{},"mui_nav":{"order":[],"renames":{"home":"Главная"},"hidden":["projects"]}}')
    get '/'
    assert_response :success
    assert_match %r{plugin_assets/redmine_sidebar_settings/sidebar_settings_mui[^"]*\.js}, response.body
    assert_match %r{window\.RedmineSidebarSettingsMui}, response.body
    assert_match %r{"hidden":\["projects"\]}, response.body
  end

  test 'mui_nav config is not injected when empty' do
    set_config('{"menus":{},"mui_nav":{}}')
    get '/'
    assert_response :success
    assert_no_match %r{RedmineSidebarSettingsMui}, response.body
  end
end
