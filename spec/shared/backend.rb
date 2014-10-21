RSpec.shared_examples 'caching_backend' do
  let(:response){ Rack::Response.new(['value'], 200, {}) }
  after(:each) do
    backend.flush!
  end
  it 'store response' do
    expect{backend.store('key', response, Grape::Cache::Backend::CacheEntryMetadata.new)}.not_to raise_error
    expect(backend.fetch('key').body).to eq(response.body)
  end

  describe 'cache expiration' do
    let(:md) { Grape::Cache::Backend::CacheEntryMetadata.new(expire_at: 1.second.from_now) }
    before(:each) do
      expect{backend.store('key', response, md)}.not_to raise_error
    end

    it 'expire cache if expiration date provided' do
      expect(backend.fetch('key').body).to eq(response.body)
      expect(backend.fetch_metadata('key')).to eq(md)
      sleep(1)
      expect(backend.fetch('key')).to be_nil
      expect(backend.fetch_metadata('key')).to eq(nil)
    end
  end

  it 'fetch response metadata' do
    md = Grape::Cache::Backend::CacheEntryMetadata.new(expire_at: 1.second.from_now)
    expect{backend.store('key', response, md)}.not_to raise_error
    expect(backend.fetch_metadata('key')).to eq(md)
  end
end