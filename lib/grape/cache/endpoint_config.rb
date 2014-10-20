require 'digest'
require 'digest/murmurhash'
module Grape
  module Cache
    class EndpointCacheConfig
      attr_accessor :expire_after

      def initialize(*args)
        args.extract_options!.each{|key, value| send("#{key}=", value)}
      end

      def cache_key(&block)
        @cache_key_block = block
      end

      def etag(&block)
        @etag_check_block = block
      end

      def last_modified(&block)
        @last_modified_block = block
      end

      # @param endpoint[Grape::Endpoint]
      # @param middleware[Grape::Cache::Middleware]
      # @param env[Hash]
      def validate_cache(endpoint, middleware, env)
        @endpoint = endpoint
        @cache_key = create_cache_key(endpoint, env)

        expire_at =

        check_etag(endpoint, env)
        check_modified_since(endpoint, env)

        if response = middleware.backend.fetch(cache_key)
          throw :cache_hit, response
        end

        env['grape.cache.capture_key'] = @cache_key
        env['grape.cache.expire_at'] = @expire_after.from_now if @expire_after
      end

      private
      def cache_key_array(endpoint)
        endpoint.declared(endpoint.params)
      end

      def create_cache_key(endpoint, env)
        cache_key_ary = cache_key_array(endpoint)
        cache_key_block = @cache_key_block
        [
            env['REQUEST_METHOD'].to_s,
            env['PATH_INFO'],
            env['HTTP_ACCEPT_VERSION'].to_s,
            Digest::MurmurHash64B.hexdigest((cache_key_block ? endpoint.instance_exec(cache_key_ary, env, &cache_key_block) : cache_key_ary).to_s)
        ].inject(&:+)
      end

      def check_etag(endpoint, env)
        return unless env['HTTP_IF_NONE_MATCH'] and @etag_check_block
        @etag = Digest::MurmurHash64B.hexdigest(endpoint.instance_eval(&@etag_check_block))

        throw :cache_hit, Rack::Response.new([], 304, 'ETag' => @etag) if @etag == env['HTTP_IF_NONE_MATCH']
        endpoint.header('ETag' => @etag)
        endpoint.header('Cache-Control','public')
      end

      def check_modified_since(endpoint, env)
        if @last_modified_block
          return unless (env['HTTP_IF_MODIFIED_SINCE'] || env['HTTP_IF_UNMODIFIED_SINCE'])
          if_modified = env['HTTP_IF_MODIFIED_SINCE'] && Time.httpdate(env['HTTP_IF_MODIFIED_SINCE'])
          if_unmodified = env['HTTP_IF_UNMODIFIED_SINCE'] && Time.httpdate(env['HTTP_IF_UNMODIFIED_SINCE'])
          last_modified = endpoint.instance_eval(&@last_modified_block)
          throw :cache_hit, Rack::Response.new([], 304, 'Last-Modified' => last_modified.httpdate) if if_modified and (last_modified <= if_modified)
          throw :cache_hit, Rack::Response.new([], 304, 'Last-Modified' => last_modified.httpdate) if if_unmodified and (last_modified > if_unmodified)
          endpoint.header('Last-Modified' => last_modified.httpdate)
          endpoint.header('Cache-Control','public')
        end
        if @expire_after
          endpoint.header('Cache-Control', 'max-age='+@expire_after.to_i.to_s)
          return unless (env['HTTP_IF_MODIFIED_SINCE'] || env['HTTP_IF_UNMODIFIED_SINCE'])
          if_modified = env['HTTP_IF_MODIFIED_SINCE'] && Time.httpdate(env['HTTP_IF_MODIFIED_SINCE'])
          if_unmodified = env['HTTP_IF_UNMODIFIED_SINCE'] && Time.httpdate(env['HTTP_IF_UNMODIFIED_SINCE'])
          throw :cache_hit, Rack::Response.new([], 304) if if_modified and (if_modified + @expire_after > Time.now)
          throw :cache_hit, Rack::Response.new([], 304) if if_unmodified and (if_unmodified < Time.now - @expire_after)
        end
      end
    end
  end
end
