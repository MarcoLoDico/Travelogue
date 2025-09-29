require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Travelogue
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # CORS for OAuth dev flow (development only)
    if Rails.env.development?
      config.middleware.insert_before 0, Rack::Cors do
        allow do
          origins /\Ahttps?:\/\/(localhost|127\.0\.0\.1)(:\d+)?\z/
          # Allow all app routes in dev to avoid localhost vs 127.0.0.1 cross-origin issues
          resource "*", headers: :any, methods: [ :get, :post, :options ], credentials: true
        end
      end
    end

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
