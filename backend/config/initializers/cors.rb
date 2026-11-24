# The React app is served from a different origin (Render static site / Vite dev server).
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins Rails.configuration.x.frontend_origin

    resource "*",
             headers: :any,
             methods: %i[get post put patch delete options head]
  end
end
