require_relative 'memory'
module Grape
  module Cache
    module Backend
      class Redis < Memory
        def initialize(redis_connection)
          raise 'Expecting redis connection here' unless redis_connection
          @storage = redis_connection
        end

        def store(key, response, expire_after)
          args = [key, 'code', response.code.to_s, 'headers', Marshal.dump(response.headers), 'body', Marshal.dump(response.body)]
          if expire_after
            storage.multi
            storage.hmset(*args)
            storage.expireat key, expire_after
            storage.exec
          else
            storage.hmset(*args)
          end
        end
        def fetch(key)
          code, headers, body = storage.get(key, 'code', 'headers', 'body')
          Rack::Response.new(Marshal.load(body), code.to_i, Marshal.load(headers))
        rescue
          nil
        end

        def fetch_headers(key)
          Marshal.load(storage.hget(key, 'headers'))
        rescue
          nil
        end
        private
        def storage
          @storage
        end
      end
    end
  end
end