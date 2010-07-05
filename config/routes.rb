ActionController::Routing::Routes.draw do |map|
  # map.resources :experiments

  map.resources :roc_groups

  map.resources :aucs

  map.resources :matrix_pairs

  map.resource :meta, :member => {:status => :get}, :controller => "meta"

  # The priority is based upon order of creation: first created -> highest priority.

  map.resources :matrices, :has_many => [:phenotypes], :member => {:expand_experiments => :get, :collapse_experiments => :get, :reload => :put} do |matrices|
    matrices.resources :experiments, :member => {:against => :get}
    matrices.resources :phenotypes, :member => {:edit_observations => :get, :update_observations => :put}
    matrices.resources :john_experiments
    matrices.resources :john_predictors
    matrices.resources :john_distributions
    matrices.resources :integrators

    matrices.resources :martin_experiments
  end

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products
  #   map.resources :matrices

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
