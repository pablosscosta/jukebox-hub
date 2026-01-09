Rails.application.routes.draw do

  resources :sessions, only: [:index, :create, :show, :update, :destroy] do
    resources :users, only: [:index, :create]
    resources :queue_items, only: [:index, :create, :update] do
      member do
        patch :mark_as_played
      end
    end
  end

end
