require File.expand_path('../../test_helper', __FILE__)

class RedmineSidebarSettingsMenuApplierTest < ActiveSupport::TestCase
  def root(menu = :top_menu)
    Redmine::MenuManager.map(menu).menu_items.root
  end

  def names(menu = :top_menu)
    root(menu).children.map { |c| c.name.to_s }
  end

  def item(name, menu = :top_menu)
    root(menu).children.find { |c| c.name.to_s == name }
  end

  def set_config(json)
    Setting.plugin_redmine_sidebar_settings = {'menu_json' => json}
    RedmineSidebarSettings::MenuApplier.apply!
  end

  def setup
    Redmine::MenuManager.map(:application_menu) do |menu|
      menu.push :rsb_test_a, {controller: 'welcome'}, :caption => 'Test A'
      menu.push :rsb_test_b, {controller: 'welcome'}, :caption => 'Test B'
    end
  end

  def teardown
    set_config('{"menus":{},"mui_nav":{}}')
    mapper = Redmine::MenuManager.map(:application_menu)
    mapper.delete(:rsb_test_a)
    mapper.delete(:rsb_test_b)
    applier = RedmineSidebarSettings::MenuApplier
    applier.stash.delete(:application_menu)
    applier.originals.delete(:application_menu)
  end

  test 'renames, hides and reorders top_menu items (legacy flat config)' do
    original_home = item('home').caption
    set_config('{"order":["projects","home"],"renames":{"home":"Старт"},"hidden":["help"]}')

    assert_not_includes names, 'help'
    assert_equal 'Старт', item('home').caption
    assert_operator names.index('projects'), :<, names.index('home')
    assert_not_equal original_home, item('home').caption
  end

  test 'apply is idempotent' do
    json = '{"menus":{"application_menu":{"order":["rsb_test_b","rsb_test_a"],"renames":{"rsb_test_a":"А"},"hidden":[]}},"mui_nav":{}}'
    set_config(json)
    first = names(:application_menu)
    set_config(json)
    assert_equal first, names(:application_menu)
  end

  test 'hidden item can be restored from the same settings (application_menu)' do
    set_config('{"menus":{"application_menu":{"order":[],"renames":{},"hidden":["rsb_test_a"]}},"mui_nav":{}}')
    assert_not_includes names(:application_menu), 'rsb_test_a'

    set_config('{"menus":{"application_menu":{"order":[],"renames":{},"hidden":[]}},"mui_nav":{}}')
    assert_includes names(:application_menu), 'rsb_test_a'
  end

  test 'removing a rename restores the original caption (application_menu)' do
    set_config('{"menus":{"application_menu":{"order":[],"renames":{"rsb_test_a":"Переименовано"},"hidden":[]}},"mui_nav":{}}')
    assert_equal 'Переименовано', item('rsb_test_a', :application_menu).caption

    set_config('{"menus":{"application_menu":{"order":[],"renames":{},"hidden":[]}},"mui_nav":{}}')
    assert_equal 'Test A', item('rsb_test_a', :application_menu).caption
  end

  test 'items missing from order keep their relative order' do
    before = names
    set_config('{"order":["home"],"renames":{},"hidden":[]}')
    after = names
    assert_equal 'home', after.first
    assert_equal before.map(&:to_s) - ['home'], after[1..]
  end

  test 'broken stored config leaves the menu native' do
    before = names
    Setting.plugin_redmine_sidebar_settings = {'menu_json' => 'not json at all'}
    RedmineSidebarSettings::MenuApplier.apply!
    assert_equal before, names
  end
end
