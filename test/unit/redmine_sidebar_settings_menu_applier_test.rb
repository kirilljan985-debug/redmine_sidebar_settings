require File.expand_path('../../test_helper', __FILE__)

class RedmineSidebarSettingsMenuApplierTest < ActiveSupport::TestCase
  def root
    Redmine::MenuManager.map(RedmineSidebarSettings::MENU).menu_items.root
  end

  def names
    root.children.map { |c| c.name.to_s }
  end

  def item(name)
    root.children.find { |c| c.name.to_s == name }
  end

  def set_config(json)
    Setting.plugin_redmine_sidebar_settings = {'menu_json' => json}
    RedmineSidebarSettings::MenuApplier.apply!
  end

  def teardown
    set_config('{"order":[],"renames":{},"hidden":[]}')
  end

  test 'renames, hides and reorders menu items' do
    original_home = item('home').caption
    set_config('{"order":["projects","home"],"renames":{"home":"Старт"},"hidden":["help"]}')

    assert_not_includes names, 'help'
    assert_equal 'Старт', item('home').caption
    assert_operator names.index('projects'), :<, names.index('home')
    assert_not_equal original_home, item('home').caption
  end

  test 'apply is idempotent' do
    json = '{"order":["projects","home"],"renames":{"home":"Старт"},"hidden":["help"]}'
    set_config(json)
    first = names.dup
    set_config(json)
    assert_equal first, names
  end

  test 'hidden item can be restored from the same settings' do
    set_config('{"order":[],"renames":{},"hidden":["help"]}')
    assert_not_includes names, 'help'

    set_config('{"order":[],"renames":{},"hidden":[]}')
    assert_includes names, 'help'
  end

  test 'removing a rename restores the original caption' do
    original = item('home').caption
    set_config('{"order":[],"renames":{"home":"Старт"},"hidden":[]}')
    assert_equal 'Старт', item('home').caption

    set_config('{"order":[],"renames":{},"hidden":[]}')
    assert_equal original, item('home').caption
  end

  test 'items missing from order keep their relative order' do
    before = names
    set_config('{"order":["home"],"renames":{},"hidden":[]}')
    after = names
    assert_equal 'home', after.first
    rest = after[1..]
    assert_equal before.map(&:to_s) - ['home'], rest
  end

  test 'broken stored config leaves the menu native' do
    before = names
    Setting.plugin_redmine_sidebar_settings = {'menu_json' => 'not json at all'}
    RedmineSidebarSettings::MenuApplier.apply!
    assert_equal before, names
  end
end
