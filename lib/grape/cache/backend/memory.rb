module Grape
  module Cache
    module Backend
      class Memory
        # @param key[String] Cache key
        # @param response[Rack::Response]
        # @param expire_after[Integer] Expiration Unix timestamp
        def store(key, response, expire_at = nil)
          @storage[key] = [response, expire_at]
        end
        # @param key[String] Cache key
        def fetch(key)
          response, expire_at = storage[key]
          return response if response.nil?

          if expire_at && expire_at < Time.now
            @storage.delete(key)
            return nil
          end

          response
        end
        private
        def storage
          @storage ||= {}
        end
      end
    end
  end
end