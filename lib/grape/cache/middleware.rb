require_relative 'backend/memory'

module Grape
  module Cache
    class Middleware
      attr_accessor :backend
      def initialize(*args)
        options = {backend: Grape::Cache::Backend::Memory.new}.merge(args.extract_options!)
        @app = args.first
        @backend = options[:backend]
      end

      def call(env)
        env['grape.cache'] = self
        result = catch(:cache_hit) { @app.call(env) }
        if env['grape.cache.capture_key']
          backend.store(env['grape.cache.capture_key'], result)
        end
        result
      end
    end
  end
end