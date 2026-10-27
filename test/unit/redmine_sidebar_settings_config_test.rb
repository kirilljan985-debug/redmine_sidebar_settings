require File.expand_path('../../test_helper', __FILE__)

class RedmineSidebarSettingsConfigTest < ActiveSupport::TestCase
  test 'parse returns empty config for empty json' do
    assert_equal RedmineSidebarSettings::Config::EMPTY, RedmineSidebarSettings::Config.parse('[]')
    assert_equal RedmineSidebarSettings::Config::EMPTY, RedmineSidebarSettings::Config.parse('{}')
  end

  test 'parse normalizes a v2 config' do
    config = RedmineSidebarSettings::Config.parse(
      '{"menus":{"application_menu":{"order":["issues"],"renames":{"issues":"Задачи"}}},' \
      '"mui_nav":{"hidden":["projects"],"custom":[{"url":"/projects/x/wiki/Info","title":"Инструкция"}]}}'
    )
    assert_equal({'order' => ['issues'], 'renames' => {'issues' => 'Задачи'}, 'hidden' => [], 'custom' => []},
                 config['menus']['application_menu'])
    assert_equal({'order' => [], 'renames' => {}, 'hidden' => ['projects'],
                  'custom' => [{'id' => 'c1', 'url' => '/projects/x/wiki/Info', 'title' => 'Инструкция'}]},
                 config['mui_nav'])
  end

  test 'parse normalizes mui_nav custom links' do
    config = RedmineSidebarSettings::Config.parse(
      '{"mui_nav":{"custom":[{"url":"/projects/fregat/wiki/Инструкция","title":"Инструкция"},' \
      '{"url":"https://example.com","title":"Внешняя"}]}}'
    )
    assert_equal 2, config['mui_nav']['custom'].size
    assert_equal({'id' => 'c1', 'url' => '/projects/fregat/wiki/Инструкция', 'title' => 'Инструкция'},
                 config['mui_nav']['custom'].first)
    assert_equal('c2', config['mui_nav']['custom'].second['id'])
  end

  test 'parse rejects custom links without url or title' do
    assert_raises(RedmineSidebarSettings::ValidationError) do
      RedmineSidebarSettings::Config.parse('{"mui_nav":{"custom":[{"url":"/x","title":""}]}}')
    end
    assert_raises(RedmineSidebarSettings::ValidationError) do
      RedmineSidebarSettings::Config.parse('{"mui_nav":{"custom":[{"url":"java script:alert(1)","title":"X"}]}}')
    end
  end

  test 'legacy flat config maps to top_menu' do
    config = RedmineSidebarSettings::Config.parse(
      '{"order":["projects","home"],"renames":{"home":"Старт"},"hidden":["help"]}'
    )
    assert_equal({'order' => ['projects', 'home'], 'renames' => {'home' => 'Старт'}, 'hidden' => ['help'], 'custom' => []},
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
