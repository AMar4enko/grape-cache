module Grape
  module Cache
    class EndpointCacheConfig
      def initialize(*args)
        args.extract_options!.each{|key, value| send("@#{key}=", value)}
      end

      def etag(&block)
        @etag_check_block = block
      end
      def last_modified(&block)
        @last_modified_block = block
      end

      def validate_cache(middleware, env)
        @cache_key = cache_key
        if response = middleware.backend.fetch(cache_key)
          throw :cache_hit, response
        end
        env['grape.cache.capture_key'] = @cache_key
      end
      private
      def cache_key
        'cache_key'
      end
    end
  end
end
