RedmineApp::Application.routes.draw do
  get 'sidebar_settings', to: 'sidebar_settings#index'
  post 'sidebar_settings/update', to: 'sidebar_settings#update'
end
