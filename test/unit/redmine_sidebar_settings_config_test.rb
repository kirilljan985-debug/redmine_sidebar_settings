require File.expand_path('../../test_helper', __FILE__)

class RedmineSidebarSettingsConfigTest < ActiveSupport::TestCase
  test 'parse returns empty config for empty json' do
    assert_equal({'order' => [], 'renames' => {}, 'hidden' => []}, RedmineSidebarSettings::Config.parse('[]'))
    assert_equal RedmineSidebarSettings::Config::EMPTY, RedmineSidebarSettings::Config.parse('{}')
  end

  test 'parse normalizes a valid config' do
    config = RedmineSidebarSettings::Config.parse(
      '{"order":[" home ","projects"],"renames":{"home":"Старт"},"hidden":["help"]}'
    )
    assert_equal ['home', 'projects'], config['order']
    assert_equal({'home' => 'Старт'}, config['renames'])
    assert_equal ['help'], config['hidden']
  end

  test 'parse rejects non-object json' do
    assert_raises(RedmineSidebarSettings::ValidationError) do
      RedmineSidebarSettings::Config.parse('["home"]')
    end
  end

  test 'parse rejects broken json' do
    assert_raises(RedmineSidebarSettings::ValidationError) do
      RedmineSidebarSettings::Config.parse('{]')
    end
  end

  test 'parse rejects invalid order entries' do
    assert_raises(RedmineSidebarSettings::ValidationError) do
      RedmineSidebarSettings::Config.parse('{"order":"home"}')
    end
    assert_raises(RedmineSidebarSettings::ValidationError) do
      RedmineSidebarSettings::Config.parse('{"order":["bad name!"]}')
    end
  end

  test 'parse rejects renames without caption' do
    assert_raises(RedmineSidebarSettings::ValidationError) do
      RedmineSidebarSettings::Config.parse('{"renames":{"home":""}}')
    end
  end
end
