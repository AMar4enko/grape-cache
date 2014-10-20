module Grape
  module Cache
    module Backend
      class Memory
        # @param key[String] Cache key
        # @param response[Rack::Response]
        # @param expire_after[Integer] Expiration Unix timestamp
        def store(key, response, expire_after = nil)
          @storage[key] = [response, expire_after]
        end
        # @param key[String] Cache key
        def fetch(key)
          response, expire_after = storage[key]
          return response if response.nil?

          if expire_after && expire_after < Time.now.to_i
            @storage.delete(key)
            return nil
          end

          return response
        end
        # @param key[String] Cache key
        def fetch_headers(key)
          return nil unless response = fetch(key)
          response.headers
        end
        private
        def storage
          @storage ||= {}
        end
      end
    end
  end
end