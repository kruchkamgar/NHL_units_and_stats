require_relative 'boot'
require 'rack'
require 'rack/cors'
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module HockeyApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # CORS
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins /\Ahttp:\/\/localhost:\d+\z/
        resource '*', headers: :any, methods: :any
      end
    end

  end
end
