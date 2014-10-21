require 'spec_helper'
require 'mock_redis'
require_relative '../../../../spec/shared/backend'
require_relative '../../../../lib/grape/cache/backend/redis'

describe 'Redis backend' do
  it_behaves_like 'caching_backend' do
    let(:backend) { Grape::Cache::Backend::Redis.new(MockRedis.new) }
  end

  define '.initialize' do
    let(:backend_class) {
      Class.new(Grape::Cache::Backend::Redis) do
        public :storage
      end
    }

    it 'supports storage definition with lambda' do
      redis = MockRedis.new
      backend_class.new(lambda{ redis })
      expect(backend_class.storage).to eq(redis)
    end
  end
end
