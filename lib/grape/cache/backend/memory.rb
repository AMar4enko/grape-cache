require_relative 'cache_entry_metadata'

module Grape
  module Cache
    module Backend
      class Memory
        # @param key[String] Cache key
        # @param response[Rack::Response]
        # @param metadata[Grape::Cache::Backend::CacheEntryMetadata] Expiration time
        def store(key, response, metadata)
          storage[key] = [response, metadata]
        end
        # @param key[String] Cache key
        def fetch(key)
          response, metadata = storage[key]

          return response if response.nil?

          if metadata.expired?
            storage.delete(key)
            return nil
          end

          response
        end

        # @param key[String] Cache key
        def fetch_metadata(key)
          return nil unless storage.has_key?(key)
          storage[key].last
        end

        def flush!
          storage.clear
        end

        private
        def storage
          @storage ||= {}
        end
      end
    end
  end
end