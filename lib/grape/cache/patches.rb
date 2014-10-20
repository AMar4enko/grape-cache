require 'grape'

module Grape
  class Endpoint
    alias_method :_call, :call
    def call(env)
      _call(env) unless options[:route_options][:cache]
      cache_options = options[:route_options][:cache]

    end
  end
end