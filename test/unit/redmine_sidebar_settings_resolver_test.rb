require File.expand_path('../../test_helper', __FILE__)

class RedmineSidebarSettingsResolverTest < ActiveSupport::TestCase
  def rule(page)
    {'page' => page, 'action' => 'hide', 'target' => {'kind' => 'section', 'heading' => page}}
  end

  test 'selects only rules matching the page' do
    rules = [rule('*'), rule('issues/*'), rule('issues/index'), rule('wiki/show')]
    result = RedmineSidebarSettings::Resolver.for_page(rules, 'issues', 'index')
    assert_equal ['*', 'issues/*', 'issues/index'], result.map { |r| r['page'] }
  end

  test 'orders rules from generic to specific' do
    rules = [rule('issues/index'), rule('*'), rule('issues/*')]
    result = RedmineSidebarSettings::Resolver.for_page(rules, 'issues', 'index')
    assert_equal ['*', 'issues/*', 'issues/index'], result.map { |r| r['page'] }
  end

  test 'preserves stored order within a group' do
    rules = [rule('issues/index'), rule('issues/index'), rule('*')]
    result = RedmineSidebarSettings::Resolver.for_page(rules, 'issues', 'index')
    assert_equal ['*', 'issues/index', 'issues/index'], result.map { |r| r['page'] }
  end

  test 'exact page rule wins over module rule regardless of stored order' do
    rules = [rule('issues/show'), rule('issues/*')]
    result = RedmineSidebarSettings::Resolver.for_page(rules, 'issues', 'index')
    assert_equal ['issues/*'], result.map { |r| r['page'] }
  end
end
