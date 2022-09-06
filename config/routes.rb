Rails.application.routes.draw do
  resource :users, only: [:create]
  post "/login", to: "auth#login"
  get "/auto_login", to: "auth#auto_login"
  get "/user_is_authed", to: "auth#user_is_authed"
  get "/users" => "users#index"
  get 'planes/index'
  get 'planes/new'
  get 'planes/edit'
  get 'planes/show'
  get 'planes/destroy'
  get 'flights/index'
  get 'flights/new'
  get 'flights/edit'
  get 'flights/show'
  get 'flights/destroy'
  get 'bookings/index'
  get 'bookings/show'
  get 'bookings/edit'
  get 'bookings/new'
  get 'bookings/destroy'
  get 'users/index'
  get 'users/show'
  get 'users/edit'
  get 'users/new'
  get 'users/destroy'
end
