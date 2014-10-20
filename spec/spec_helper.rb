require 'grape/cache'
require 'rack'
require 'rack/test'
require 'grape'
require 'rspec/mocks'

RSpec.configure do |c|
  c.include Rack::Test::Methods
end