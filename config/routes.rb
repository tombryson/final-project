Rails.application.routes.draw do
  resource :users, only: [:create]
  post "/login", to: "auth#login"
  get "/auto_login", to: "auth#auto_login"
  get "/user_is_authed", to: "auth#user_is_authed"
  get "/users" => "users#index"
  get "/search/:from/:to", to: "flights#search"
  get "/flights/:id", to: "flights#show"
  resource :planes
  resource :flights
  resource :bookings
  resource :users
end
