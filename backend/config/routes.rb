Rails.application.routes.draw do
  # Health check used by Render: 200 if the app boots.
  get "up" => "rails/health#show", as: :rails_health_check

  # Host login with Spotify. See docs/api.md.
  get "auth/spotify", to: "auth/spotify#start", as: :spotify_login
  get "auth/spotify/callback", to: "auth/spotify#callback", as: :spotify_callback
  post "auth/token", to: "auth/tokens#create"
  delete "auth/token", to: "auth/tokens#destroy"

  get "me", to: "me#show"
  get "me/devices", to: "me/devices#index"
  get "me/party", to: "me/party#show"

  resources :parties, only: %i[create show] do
    resources :participants, only: :create
    get "participants/me", to: "participants#me"
    get "search", to: "searches#show"
    get "queue", to: "queue_items#index"
    post "queue", to: "queue_items#create"
  end
end
