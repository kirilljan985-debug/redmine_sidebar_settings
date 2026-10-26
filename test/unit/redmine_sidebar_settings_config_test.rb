require File.expand_path('../../test_helper', __FILE__)

class RedmineSidebarSettingsConfigTest < ActiveSupport::TestCase
  test 'parse returns empty config for empty json' do
    assert_equal RedmineSidebarSettings::Config::EMPTY, RedmineSidebarSettings::Config.parse('[]')
    assert_equal RedmineSidebarSettings::Config::EMPTY, RedmineSidebarSettings::Config.parse('{}')
  end

  test 'parse normalizes a v2 config' do
    config = RedmineSidebarSettings::Config.parse(
      '{"menus":{"application_menu":{"order":["issues"],"renames":{"issues":"Задачи"}}},' \
      '"mui_nav":{"hidden":["projects"]}}'
    )
    assert_equal({'order' => ['issues'], 'renames' => {'issues' => 'Задачи'}, 'hidden' => []},
                 config['menus']['application_menu'])
    assert_equal({'order' => [], 'renames' => {}, 'hidden' => []}, config['menus']['top_menu'])
    assert_equal({'order' => [], 'renames' => {}, 'hidden' => ['projects']}, config['mui_nav'])
  end

  test 'legacy flat config maps to top_menu' do
    config = RedmineSidebarSettings::Config.parse(
      '{"order":["projects","home"],"renames":{"home":"Старт"},"hidden":["help"]}'
    )
    assert_equal({'order' => ['projects', 'home'], 'renames' => {'home' => 'Старт'}, 'hidden' => ['help']},
                 config['menus']['top_menu'])
    assert_equal RedmineSidebarSettings::Config::EMPTY_PART, config['mui_nav']
  end

  test 'parse rejects unknown menu keys' do
    assert_raises(RedmineSidebarSettings::ValidationError) do
      RedmineSidebarSettings::Config.parse('{"menus":{"account_menu":{}}}')
    end
  end

  test 'parse rejects broken json and scalars' do
    assert_raises(RedmineSidebarSettings::ValidationError) do
      RedmineSidebarSettings::Config.parse('{]')
    end
    assert_raises(RedmineSidebarSettings::ValidationError) do
      RedmineSidebarSettings::Config.parse('42')
    end
  end

  test 'parse rejects invalid parts with the menu name' do
    e = assert_raises(RedmineSidebarSettings::ValidationError) do
      RedmineSidebarSettings::Config.parse('{"menus":{"project_menu":{"order":"nope"}}}')
    end
    assert e.errors.any? { |m| m.include?('project_menu') }
  end
end
