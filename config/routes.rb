Rails.application.routes.draw do
  root 'items#index'

  resources :products do
    get 'confirmation', on: :member
  end

  get '/mypage' => 'items#mypage'
  get '/mypage/logout' => 'items#logout'
  namespace :mypage do
    resources :favorites, only:[:index]
    resources :listings, only: [:index]
    resources :purchasers, only: [:index]
    resources :users, only: [:edit, :update]
    resources :destinations, only: [:edit, :update]
    resources :cards, only: [:index, :new, :create, :destroy]
  end
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
