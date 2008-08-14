ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "articles"

  # See how all your routes lay out with "rake routes"

  # Authentication routes
  map.resource  :sessions
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.login  '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.activate '/activate/:activation_code', :controller => 'users', :action => 'activate'
   
  # Assets routes
  map.resources :articles,  :collection => {:list => :get, :recent => :get, :popular => :get, :live_search => :post},
                            :member => {:comments => :get}
  map.resources :assets,    :collection => {:live_search => :post, :apis => :get}
  map.resources :images,    :member => {:serve => :get, :comments => :get}, 
                            :collection => {:recent => :get, :popular => :get, :random => :post, :roulette => :get, 
                              :live_search => :post}
  map.resources :galleries, :collection => {:recent => :get, :popular => :get, :refresh_all => :post},
                            :member => {:comments => :get}
  map.resources :maps,      :collection => {:world => :get}
  map.resources :comments,  :collection => {:delete => :delete}, 
                            :member => {:approve => :put, :spam => :put, :ham => :put}
  map.resources :bookmarks
  map.resources :publications, :member => {:about => :get, :contact => :get, :privacy => :get,
                                :terms => :get, :contact => :get}
  map.resources :users
  map.resource  :messages

  map.connect "logged_exceptions/:action/:id", :controller => "logged_exceptions"

  map.index     ':year/:month/:day', :controller => 'articles', :action => 'date',
                :month => nil, :day => nil,
                :requirements => {:year => /\d{4}/, :day => /\d{1,2}/, :month => /\d{1,2}/}
                
  map.xmlrpc    'xmlrpc/api', :controller => 'xmlrpc', :action => 'api'
  
  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  map.connect '*path' , :controller => 'application' , :action => 'unrecognized?'
end
