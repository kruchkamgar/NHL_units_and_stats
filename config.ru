# This file is used by Rack-based servers to start the application.

require_relative 'config/environment'

run Rails.application
require 'rack/cors'

config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins /\Ahttp:\/\/localhost:\d+\z/
    resource '*', headers: :any, methods: :any
  end
end
