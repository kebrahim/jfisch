Jfisch::Application.routes.draw do

  # survivor_entries
  get 'my_entries' => 'survivor_entries#my_entries'
  post 'my_entries' => 'survivor_entries#save_entries'
  get '/users/:user_id/entries' => 'survivor_entries#user_entries'
  post 'user_entries/:user_id' => 'survivor_entries#save_user_entries'
  
  get 'dashboard' => 'survivor_entries#dashboard'
  get '/users/:user_id/dashboard' => 'survivor_entries#user_dashboard'

  post 'save_entry_bets' => 'survivor_entries#save_entry_bets'
  get '/survivor_entries/:id(.:format)' => 'survivor_entries#show'
  get '/ajax/survivor_entries/:id' => 'survivor_entries#ajaxshow'
 
  get 'survivor' => 'survivor_entries#survivor'
  get 'anti_survivor' => 'survivor_entries#anti_survivor'
  get 'high_roller' => 'survivor_entries#high_roller'
  get 'entries' => 'survivor_entries#all_entries'
  
  get 'kill_entries' => 'survivor_entries#kill_entries'
  get 'kill_entries/week/:number' => 'survivor_entries#kill_entries_week'
  get '/ajax/kill_entries/week/:number' => 'survivor_entries#ajax_kill_week'
  delete 'kill_entries/week/:number' => 'survivor_entries#kill_all'

  # TODO remove unused routes
  resources :survivor_bets

  resources :nfl_schedules
  get 'nfl_schedule' => 'nfl_schedules#index'
  get '/nfl_schedule/:id(.:format)' => 'nfl_schedules#show'
  post '/nfl_schedule/:id(.:format)' => 'nfl_schedules#update'
  get '/ajax/nfl_schedule/week/:number' => 'nfl_schedules#ajaxweek'
  get '/ajax/nfl_schedule/adminweek/:number' => 'nfl_schedules#ajaxadminweek'

  resources :nfl_teams

  resources :sessions
  get "logout" => "sessions#destroy", :as => "logout"
  get "login" => "sessions#new", :as => "login"
  root :to => 'sessions#new'
  
  resources :users
  get 'sign_up' => 'users#new', :as => 'sign_up'
  get 'profile' => 'users#profile'
  get '/confirm/:confirmation_code' => 'users#confirm', :as=>'confirm_user'

  resources :password_resets

  # weeks
  get 'weeks' => 'weeks#index'
  post 'weeks' => 'weeks#update'

  get '/survivor/week' => 'weeks#survivor'
  get '/ajax/survivor/week/:id' => 'weeks#ajax_survivor'
  get '/anti_survivor/week' => 'weeks#anti_survivor'
  get '/ajax/anti_survivor/week/:id' => 'weeks#ajax_anti_survivor'
  get '/high_roller/week' => 'weeks#high_roller'
  get '/ajax/high_roller/week/:id' => 'weeks#ajax_high_roller'

  # rules
  get '/survivor/rules' => 'rules#survivor'
  get '/anti_survivor/rules' => 'rules#anti_survivor'
  get '/high_roller/rules' => 'rules#high_roller'

  get '/sendgrid' => 'rules#sendgrid'

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
