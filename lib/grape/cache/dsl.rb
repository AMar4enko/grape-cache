require_relative 'endpoint_config'

module Grape
  module Cache
    module DSL
      extend ActiveSupport::Concern
      module ClassMethods
        def cache(*arguments, &block)
          config = Grape::Cache::EndpointCacheConfig.new(arguments.extract_options!)
          route_setting :cache, config
        end
        def route(methods, paths = ['/'], route_options = {}, &block)
          endpoint_options = {
              method: methods,
              path: paths,
              for: self,
              route_options: ({
                  params: Grape::DSL::Configuration.stacked_hash_to_hash(namespace_stackable(:params)) || {}
              })
                                 .deep_merge(route_setting(:description) || {})
                                 .deep_merge({cache: route_setting(:cache)} || {})
                                 .deep_merge(route_options || {})
          }
          endpoints << Grape::Endpoint.new(inheritable_setting, endpoint_options, &block)

          route_end
          reset_validations!
        end
      end
    end
  end
end
