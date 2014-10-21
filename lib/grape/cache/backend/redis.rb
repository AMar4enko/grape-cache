require_relative 'memory'
module Grape
  module Cache
    module Backend
      class Redis < Memory
        def initialize(redis_connection)
          raise 'Expecting redis connection here' unless redis_connection
          @storage = redis_connection
        end

        # @param key[String] Cache key
        # @param response[Rack::Response]
        # @param metadata[Grape::Cache::Backend::CacheEntryMetadata] Entry metadata
        def store(key, response, metadata)
          args = [key, 'status', response.status.to_s, 'headers', Marshal.dump(response.headers), 'body', Marshal.dump(response.body), 'metadata', Marshal.dump(metadata)]
          if metadata.expire_at
            storage.multi
            storage.hmset(*args)
            storage.expireat key, metadata.expire_at.to_i
            storage.exec
          else
            storage.hmset(*args)
          end
        end
        def fetch(key)
          status, headers, body = storage.hmget(key, 'status', 'headers', 'body')
          Rack::Response.new(Marshal.load(body), status.to_i, Marshal.load(headers))
        rescue
          nil
        end

        # @param key[String] Cache key
        def fetch_metadata(key)
          Marshal.load(storage.hget(key, 'metadata'))
        rescue
          nil
        end

        def flush!
          storage.flushdb
        end

        private
        def storage
          @_storage ||= @storage.respond_to?(:arity) ? @storage.call : @storage
        end
      end
    end
  end
end