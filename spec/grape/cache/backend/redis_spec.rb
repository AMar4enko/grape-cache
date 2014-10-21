require 'spec_helper'
require 'mock_redis'
require_relative '../../../../spec/shared/backend'
require_relative '../../../../lib/grape/cache/backend/redis'

describe 'Redis backend' do
  it_behaves_like 'caching_backend' do
    let(:backend) { Grape::Cache::Backend::Redis.new(MockRedis.new) }
  end
end
