Rails.application.routes.draw do
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
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
