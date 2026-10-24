require File.expand_path('../../test_helper', __FILE__)

class SidebarSettingsIntegrationTest < Redmine::IntegrationTest
  fixtures :all

  setup do
    # Redmine renders 500 pages in the test env (show_exceptions = :all);
    # raise instead so failures show the real exception and backtrace.
    Rails.application.env_config['action_dispatch.show_exceptions'] = false
  end

  test 'admin opens the settings page' do
    log_user('admin', 'admin')
    get '/sidebar_settings'
    assert_response :success
    assert_select 'form#rss-form'
    assert_select '#rules_json'
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

  test 'sanity: core pages render without the plugin involved' do
    ActionDispatch::ShowExceptions.class_eval do
      unless method_defined?(:rsb_orig_render_exception)
        alias_method :rsb_orig_render_exception, :render_exception
        def render_exception(request, exception, wrapper)
          Thread.current[:rsb_exception] = exception
          rsb_orig_render_exception(request, exception, wrapper)
        end
      end
    end

    Thread.current[:rsb_exception] = nil
    get '/'
    ex = Thread.current[:rsb_exception]
    b = response.body
    h2 = b.index('<h2')
    pre = b.index('<pre')
    note = "status=#{response.status}; SHOWEX=#{ex.inspect}; " \
           "H2=#{h2 ? b[h2, 240] : 'none'}; PRE=#{pre ? b[pre, 900] : 'none'}"
    assert_response :success, note
  end

  test 'sanity: logged-in core page renders' do
    log_user('admin', 'admin')
    get '/'
    assert_response :success, "status=#{response.status}; body=#{response.body[0, 900]}"
  end

  test 'admin saves valid rules' do
    log_user('admin', 'admin')
    post '/sidebar_settings/update', params: {
      rules_json: '[{"page":"*","action":"hide","target":{"heading":"Help"}}]'
    }
    assert_redirected_to '/sidebar_settings'
    assert_equal(
      [{'page' => '*', 'action' => 'hide', 'target' => {'heading' => 'Help'}}],
      RedmineSidebarSettings::Config.parse(Setting.plugin_redmine_sidebar_settings['rules_json'])
    )
  end

  test 'invalid rules are rejected and stored config stays intact' do
    Setting.plugin_redmine_sidebar_settings = {
      'rules_json' => '[{"page":"*","action":"hide","target":{"heading":"Help"}}]'
    }
    log_user('admin', 'admin')
    post '/sidebar_settings/update', params: {rules_json: '[{]'}
    assert_response :unprocessable_entity
    assert_equal '[]', Setting.plugin_redmine_sidebar_settings['rules_json']
  end

  test 'rules are delivered to matching pages' do
    Setting.plugin_redmine_sidebar_settings = {
      'rules_json' => '[{"page":"*","action":"hide","target":{"heading":"Help"}}]'
    }
    log_user('admin', 'admin')
    get '/issues'
    assert_response :success
    assert_match %r{window\.RedmineSidebarSettings}, response.body
    assert_match %r{plugin_assets/redmine_sidebar_settings/sidebar_settings[^"]*\.js}, response.body
  end

  test 'pages stay native when config is empty' do
    Setting.plugin_redmine_sidebar_settings = {'rules_json' => '[]'}
    log_user('admin', 'admin')
    get '/issues'
    assert_response :success
    assert_no_match %r{window\.RedmineSidebarSettings}, response.body
  end

  test 'broken config does not break page rendering' do
    Setting.plugin_redmine_sidebar_settings = {'rules_json' => 'not json at all'}
    log_user('admin', 'admin')
    get '/issues'
    assert_response :success
    assert_no_match %r{window\.RedmineSidebarSettings}, response.body
  end
end
