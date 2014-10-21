require_relative 'endpoint_cache_config'

module Grape
  module Cache
    module DSL
      extend ActiveSupport::Concern
      module ClassMethods
        def cache(*arguments, &block)
          config = Grape::Cache::EndpointCacheConfig.new(arguments.extract_options!)
          config.instance_eval(&block) if block_given?
          route_setting :cache, config
        end

        def route(methods, paths = ['/'], route_options = {}, &block)
          super(methods, paths, route_options.deep_merge({cache: route_setting(:cache)}), &block)
        end
      end
    end
  end
end
