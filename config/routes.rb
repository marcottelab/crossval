Crossval::Application.routes.draw do
  resources :genes

  # map.resources :experiments

  resources :aucs

  resources :matrix_pairs

  resource :meta do
# => {:status => :get}, :controller => "meta"
    member do
      get 'status'
    end
  end

  # The priority is based upon order of creation: first created -> highest priority.

  resources :matrices do
    member do
      get 'expand_experiments'
      get 'collapse_experiments'
      put 'reload'
      get 'graph'
      get 'view'
    end

    collection do
      get 'phenotypes'
      get 'experiments'
    end

    resources :experiments do
      member do
        get 'against'
      end
    end

    resources :phenotypes do
      member do
        get 'edit_observations'
        put 'update_observations'
        get 'list'
      end
    end

    resources :knn_experiments
    resources :integrators
  end

  # You can have the root of your site routed with "root"
  # map.root :controller => "matrices"
  root :to => "matrices#index"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
