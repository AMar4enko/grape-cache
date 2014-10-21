require 'spec_helper'
require 'mock_redis'
require_relative '../../../../spec/shared/backend'
require_relative '../../../../lib/grape/cache/backend/memory'

describe 'Memory backend' do
  it_behaves_like 'caching_backend' do
    let(:backend) { Grape::Cache::Backend::Memory.new }
  end
end
