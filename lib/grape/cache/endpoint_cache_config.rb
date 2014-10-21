require 'digest'
require 'digest/murmurhash'
module Grape
  module Cache
    class EndpointCacheConfig
      def expire_after(value = nil, &block)
        @expire_after_block = block_given? ? block : lambda{|*args| value.from_now }
      end

      def initialize(*args)
        args.extract_options!.each{|key, value| send("#{key}=", value)}
      end

      def prepare(&block)
        @prepare_block = block
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
      def validate_cache(endpoint, middleware)
        # First cache barrier - 304 cache responses for ETag and If-Last-Modified
        @prepare_block && endpoint.instance_eval(&@prepare_block)
        check_etag(endpoint)
        check_modified_since(endpoint)

        # If here, no HTTP cache hits occured
        # Retreive request metadata
        cache_key = create_cache_key(endpoint)

        catch :cache_miss do
          if metadata = middleware.backend.fetch_metadata(cache_key)
            if @etag
              throw_cache_hit(middleware, cache_key){ @etag == metadata.etag }
            end
            if @last_modified
              throw_cache_hit(middleware, cache_key){ @last_modified <= metadata.last_modified }
            end

            throw_cache_hit(middleware, cache_key)
          end
        end

        endpoint.env['grape.cache.capture_key'] = cache_key
        endpoint.env['grape.cache.capture_metadata'] = create_capture_metadata(endpoint)
      end

      private
      def cache_key_array(endpoint)
        endpoint.declared(endpoint.params)
      end

      def create_cache_key(endpoint)
        cache_key_ary = cache_key_array(endpoint)
        cache_key_block = @cache_key_block
        [
            endpoint.env['REQUEST_METHOD'].to_s,
            endpoint.env['PATH_INFO'],
            endpoint.env['HTTP_ACCEPT_VERSION'].to_s,
            Digest::MurmurHash64B.hexdigest((cache_key_block ? endpoint.instance_exec(cache_key_ary, &cache_key_block) : cache_key_ary).to_s)
        ].inject(&:+)
      end

      def check_etag(endpoint)
        return unless @etag_check_block
        @etag = Digest::MurmurHash64B.hexdigest(endpoint.instance_eval(&@etag_check_block).to_s)

        throw :cache_hit, Rack::Response.new([], 304, 'ETag' => @etag) if @etag == endpoint.env['HTTP_IF_NONE_MATCH']
        build_cache_headers(endpoint, {'ETag' => @etag})
      end

      def check_modified_since(endpoint)
        return unless @last_modified_block
        @last_modified = endpoint.instance_eval(&@last_modified_block)

        if_modified = endpoint.env['HTTP_IF_MODIFIED_SINCE'] && Time.httpdate(endpoint.env['HTTP_IF_MODIFIED_SINCE'])
        if_unmodified = endpoint.env['HTTP_IF_UNMODIFIED_SINCE'] && Time.httpdate(endpoint.env['HTTP_IF_UNMODIFIED_SINCE'])

        throw :cache_hit, Rack::Response.new([], 304, 'Last-Modified' => @last_modified.httpdate) if if_modified and (@last_modified <= if_modified)
        throw :cache_hit, Rack::Response.new([], 304, 'Last-Modified' => @last_modified.httpdate) if if_unmodified and (@last_modified > if_unmodified)
        build_cache_headers(endpoint, {'Last-Modified' => @last_modified.httpdate})
      end

      def create_capture_metadata(endpoint)
        args = {}
        args[:etag] = @etag if @etag
        args[:last_modified] = @last_modified if @last_modified
        if @expire_after_block
          args[:expire_at] = endpoint.instance_eval(&@expire_after_block)
        end

        Grape::Cache::Backend::CacheEntryMetadata.new(args)
      end

      def throw_cache_hit(middleware, cache_key, &block)
        if !block_given? || instance_eval(&block)
          if result = middleware.backend.fetch(cache_key)
            throw :cache_hit, result
          end
        end
        throw :cache_miss
      end

      def build_cache_headers(endpoint, headers = {})
        expire_after = @expire_after_block ? (Time.now - endpoint.instance_eval(&@expire_after_block)).to_i : nil

        endpoint.header('Vary','Accept,Accept-Version')
        endpoint.header('Cache-Control',"public#{expire_after ? ",max-age=#{expire_after}" : ''}")
        headers.each{|key, value| endpoint.header(key, value)}
      end
    end
  end
end
