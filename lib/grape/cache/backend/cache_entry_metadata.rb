module Grape
  module Cache
    module Backend
      class CacheEntryMetadata
        attr_accessor :etag, :last_modified, :expire_at
        def initialize(*args)
          args.extract_options!.each{|key,value| send("#{key}=", value)}
        end

        def expired?(at_time = Time.now)
          self.expire_at && (self.expire_at < at_time)
        end
      end
    end
  end
end