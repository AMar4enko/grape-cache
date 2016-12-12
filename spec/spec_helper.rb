require 'grape/cache'
require 'rack'
require 'rack/test'
require 'grape'
require 'rspec/mocks'
require 'pry'

RSpec.configure do |c|
  c.include Rack::Test::Methods
end
