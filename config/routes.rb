ActionController::Routing::Routes.draw do |map|
  # Authentication-related routes from clearance project
  map.resources :passwords,
    :controller => 'clearance/passwords',
    :only => [:new, :create]

  map.resource  :session,
    :controller => 'clearance/sessions',
    :only => [:new, :create, :destroy]

  map.resources :users, :controller => 'clearance/users' do |users|
    users.resource :password,
      :controller => 'clearance/passwords',
      :only => [:create, :edit, :update]

    users.resource :confirmation,
      :controller => 'clearance/confirmations',
      :only => [:new, :create]
  end

  # Convenience URLS
  map.login 'login',
    :controller => 'clearance/sessions', :action => 'new'
    
  map.logout 'logout',
    :controller => 'clearance/sessions', :action => 'destroy'

  # Application-specific routes
  map.resources :report_cards,
    :controller => 'report_cards',
    :only => [:index, :show]

  # Required 'account' and 'root' routes
  map.account 'account',
    :controller => 'account', :action => 'show'
    
  map.root :controller => 'home'

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
