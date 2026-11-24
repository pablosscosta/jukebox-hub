# The React app is served from a different origin (Render static site / Vite dev server).
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # In dev there can be two origins: 127.0.0.1 (host) and the Wi-Fi IP (guests' phones).
    origins(*[Rails.configuration.x.frontend_origin, Rails.configuration.x.invite_origin].uniq)

    resource "*",
             headers: :any,
             methods: %i[get post put patch delete options head]
  end
end
