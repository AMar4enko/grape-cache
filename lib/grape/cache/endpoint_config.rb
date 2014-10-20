module Grape
  module Cache
    class EndpointCacheConfig
      def etag(&block)
        @etag_check_block = block
      end
      def last_modified(&block)
        @last_modified_block = block
      end
    end
  end
end
