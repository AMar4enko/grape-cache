require "grape/cache/patches"
require "grape/cache/dsl"
require "grape/cache/version"

module Grape
  class API
    include Grape::Cache::DSL
  end
end