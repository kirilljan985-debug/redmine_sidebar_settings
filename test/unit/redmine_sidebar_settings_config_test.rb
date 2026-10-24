require File.expand_path('../../test_helper', __FILE__)

class RedmineSidebarSettingsConfigTest < ActiveSupport::TestCase
  test 'parse returns empty array for empty json' do
    assert_equal [], RedmineSidebarSettings::Config.parse('[]')
  end

  test 'parse normalizes a valid rule' do
    rules = RedmineSidebarSettings::Config.parse(
      '[{"page":" issues/index ","action":"rename","target":{"kind":"section","heading":" Запросы "},"value":"Представления"}]'
    )
    assert_equal 1, rules.size
    assert_equal({
      'page' => 'issues/index', 'action' => 'rename',
      'target' => {'kind' => 'section', 'heading' => 'Запросы'},
      'value' => 'Представления'
    }, rules.first)
  end

  test 'parse accepts css target and move rule' do
    rules = RedmineSidebarSettings::Config.parse(
      '[{"page":"*","action":"hide","target":{"css":".my-plugin-block"}},' \
      '{"page":"issues/index","action":"move","target":{"kind":"section","heading":"Запросы"},"index":0}]'
    )
    assert_equal 2, rules.size
    assert_equal({'css' => '.my-plugin-block'}, rules[0]['target'])
    assert_equal 0, rules[1]['index']
  end

  test 'parse rejects non-array json' do
    assert_raises(RedmineSidebarSettings::ValidationError) do
      RedmineSidebarSettings::Config.parse('{"page":"*"}')
    end
  end

  test 'parse rejects broken json' do
    assert_raises(RedmineSidebarSettings::ValidationError) do
      RedmineSidebarSettings::Config.parse('[{]')
    end
  end

  test 'parse accepts shorthand target without explicit kind' do
    rules = RedmineSidebarSettings::Config.parse(
      '[{"page":"*","action":"hide","target":{"heading":"Help"}},' \
      '{"page":"*","action":"rename","target":{"href":"/issues?query_id="},"value":"Filters"}]'
    )
    assert_equal({'kind' => 'section', 'heading' => 'Help'}, rules[0]['target'])
    assert_equal({'kind' => 'item', 'href' => '/issues?query_id='}, rules[1]['target'])
  end

  test 'parse rejects invalid page keys' do
    ['issues', 'issues/index/extra', 'issues /index', ''].each do |page|
      json = [{"page" => page, "action" => "hide", "target" => {"heading" => "X"}}].to_json
      e = assert_raises(RedmineSidebarSettings::ValidationError) do
        RedmineSidebarSettings::Config.parse(json)
      end
      assert e.errors.any? { |m| m.include?('rule 1') }
    end
  end

  test 'parse rejects unknown actions' do
    json = [{"page" => "*", "action" => "delete", "target" => {"heading" => "X"}}].to_json
    assert_raises(RedmineSidebarSettings::ValidationError) do
      RedmineSidebarSettings::Config.parse(json)
    end
  end

  test 'parse rejects rename without value and move without index' do
    json = [
      {"page" => "*", "action" => "rename", "target" => {"heading" => "X"}},
      {"page" => "*", "action" => "move", "target" => {"heading" => "X"}}
    ].to_json
    e = assert_raises(RedmineSidebarSettings::ValidationError) do
      RedmineSidebarSettings::Config.parse(json)
    end
    assert_equal 2, e.errors.size
  end

  test 'parse accepts wildcard module pages' do
    rules = RedmineSidebarSettings::Config.parse(
      '[{"page":"issues/*","action":"hide","target":{"kind":"section","heading":"Help"}}]'
    )
    assert_equal 'issues/*', rules.first['page']
  end

  test 'parse rejects too many rules' do
    stub = []
    501.times { stub << {"page" => "*", "action" => "hide", "target" => {"heading" => "X"}} }
    e = assert_raises(RedmineSidebarSettings::ValidationError) do
      RedmineSidebarSettings::Config.parse(stub.to_json)
    end
    assert e.errors.any? { |m| m.include?('too many rules') }
  end
end
