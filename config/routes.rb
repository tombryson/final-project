Rails.application.routes.draw do
  resource :users, only: [:create]
  post "/login", to: "auth#login"
  post "flights/submit", to: "flights#submit"
  get "/auto_login", to: "auth#auto_login"
  get "/user_is_authed", to: "auth#user_is_authed"
  get "/users" => "users#index"
  get "/search/:from/:to", to: "flights#search"
  get "/flights/:id", to: "flights#show"
  get "/flights", to: 'flights#index'
  post '/flights/:id/confirmation' => 'flights#confirmation'
  get "/bookings/:id", to: "bookings#show"
  post "/bookings" => "bookings#create"
  get "/users/:id", to: "users#show"
  resource :planes
  resource :flights do
    collection do
      post 'submit'
    end
  end
  resource :bookings
  resource :users
end
