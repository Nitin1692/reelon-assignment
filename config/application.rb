require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CodespacesTryRails
  class Application < Rails::Application
    config.load_defaults 7.1

    config.time_zone = "UTC"
    config.eager_load_paths << Rails.root.join("app/services")

    # CORS configuration
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins "*"
        resource "*",
          headers: :any,
          methods: [:get, :post, :put, :patch, :delete, :options, :head],
          expose: ["Authorization"],
          max_age: 600
      end
    end
  end
end
