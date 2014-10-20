require "grape/cache/patches"
require "grape/cache/dsl"
require "grape/cache/version"
require "grape/cache/backend/memory"
require "grape/cache/middleware"

module Grape
  class API
    include Grape::Cache::DSL
  end
end