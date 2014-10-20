require 'grape'

module Grape
  class Endpoint
    alias_method :_call, :call
    def call(env)
      return _call(env) unless options[:route_options][:cache] || env['grape.cache'].nil?
      options[:route_options][:cache].validate_cache(env['grape.cache'], env)
      _call(env)
    end
  end
end