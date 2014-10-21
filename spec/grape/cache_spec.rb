require 'spec_helper'

describe Grape::Cache do
  before do
    @backend = backend = Class.new(Grape::Cache::Backend::Memory) do
      public :storage
    end.new

    @grape_app = grape_app = Class.new(Grape::API) do
      format :json
    end

    @app = Rack::Builder.new do
      use Grape::Cache::Middleware, backend: backend
      run grape_app
    end.to_app
  end

  after(:each) { @grape_app.reset! }

  let :backend do
    @backend
  end

  def app
    @app
  end

  describe 'modyfing cache key contents' do
    let(:cache_spy) { spy('GET spy', miss: true) }
    before do
      _cache_spy = cache_spy
      @grape_app.cache do
        expire_after 10.seconds
        cache_key {|key_hash|
          key_hash[:header] = headers['My-Test']
          key_hash
        }
      end
      @grape_app.get :cache_key do
        _cache_spy.miss(headers['My-Test'])
        {test_key: 'test_value'}
      end
    end
    it 'alter cache key with cache_key block' do
      get '/cache_key.json?n=1', {}, {'HTTP_MY_TEST' => 1}
      expect(last_response.status).to eq(200)
      get '/cache_key.json?n=1', {}, {'HTTP_MY_TEST' => 1}
      expect(last_response.status).to eq(200)

      expect(cache_spy).to have_received(:miss).once.with(1)

      get '/cache_key.json?n=1', {}, {'HTTP_MY_TEST' => 2}
      expect(last_response.status).to eq(200)
      get '/cache_key.json?n=1', {}, {'HTTP_MY_TEST' => 2}
      expect(last_response.status).to eq(200)

      expect(cache_spy).to have_received(:miss).once.with(2)
    end
  end

  describe 'etag' do
    let(:cache_spy) { spy('GET spy', miss: true) }
    before do
      _cache_spy = cache_spy
      @grape_app.cache do
        etag { headers['Etag-Content'] }
      end
      @grape_app.get :test do
        _cache_spy.miss(headers['Etag-Content'])
        headers['Etag-Content']
      end
    end

    it 'respond with 304 if etag not changed and header provided' do
      get '/test', {}, {'HTTP_ETAG_CONTENT' => 'etag content'}
      expect(last_response.status).to eq(200)
      etag = last_response.headers['ETag']
      expect(etag).not_to be_nil
      get '/test', {}, {'HTTP_ETAG_CONTENT' => 'etag content', 'HTTP_IF_NONE_MATCH' => last_response.headers['ETag']}
      expect(last_response.status).to eq(304)
      get '/test', {}, {'HTTP_ETAG_CONTENT' => 'etag content2', 'HTTP_IF_NONE_MATCH' => last_response.headers['ETag']}
      expect(last_response.status).to eq(200)
      expect(last_response.headers['ETag']).not_to eq(etag)
    end

    it 'respond with cached content if etag not changed and no header provided' do
      get '/test', {}, {'HTTP_ETAG_CONTENT' => 'etag content'}
      expect(last_response.status).to eq(200)
      etag = last_response.headers['ETag']
      expect(etag).not_to be_nil

      get '/test', {}, {'HTTP_ETAG_CONTENT' => 'etag content'}
      expect(last_response.status).to eq(200)
      expect(cache_spy).to have_received(:miss).once.with('etag content')
    end
  end

  describe 'last_modified' do
    last_modified_fixed = 2.hours.ago
    let(:cache_spy) { spy('GET spy', miss: true) }
    before do
      _cache_spy = cache_spy
      @grape_app.cache do
        last_modified { last_modified_fixed }
      end
      @grape_app.get :test do
        _cache_spy.miss
      end
    end

    it 'caches content with Last-Modified' do
      get '/test', {}
      expect(last_response.status).to eq(200)
      last_modified = last_response.headers['Last-Modified']
      expect(last_modified).not_to be_nil

      get '/test', {}, {'HTTP_IF_MODIFIED_SINCE' => 1.hour.ago.httpdate}
      expect(last_response.status).to eq(304)
    end

    it 'respond with cached content if last_modified not changed and no header provided' do
      get '/test', {}
      expect(last_response.status).to eq(200)
      get '/test', {}
      expect(last_response.status).to eq(200)
      expect(cache_spy).to have_received(:miss).once
    end
  end

  describe 'expire_after' do
    let(:cache_spy) { spy('GET spy', miss: true) }
    before do
      _cache_spy = cache_spy
      @grape_app.cache do
        expire_after 2.seconds
        etag { 'etag' }
      end
      @grape_app.get :expire_after_value do
        _cache_spy.miss(:after_value)
      end

      @grape_app.cache do
        expire_after { 3.seconds.from_now }
        etag { 'etag' }
      end
      @grape_app.get :expire_after_block do
        _cache_spy.miss(:after_block)
      end
    end

    it 'expires cache in 2 seconds defined with value' do
      get '/expire_after_value'
      get '/expire_after_value'
      expect(cache_spy).to have_received(:miss).once.with(:after_value)
      sleep(2)
      get '/expire_after_value'
      expect(cache_spy).to have_received(:miss).twice.with(:after_value)
    end

    it 'expires cache in 3 seconds defined with block' do
      get '/expire_after_block'
      get '/expire_after_block'
      expect(cache_spy).to have_received(:miss).once.with(:after_block)
      sleep(3)
      get '/expire_after_block'
      expect(cache_spy).to have_received(:miss).twice.with(:after_block)
    end
  end

  describe 'prepare block' do
    let(:cache_spy) { spy('GET spy', miss: true) }

    before do
      _cache_spy = cache_spy
      @grape_app.cache do
        prepare { @etag = '123456' }
        etag { @etag }
      end
      @grape_app.get :with_prepare do
        _cache_spy.miss(@etag)
        {etag: @etag}
      end
    end

    it 'executed in endpoint scope before cache validation' do
      expect{get '/with_prepare'}.to_not raise_error
      expect(last_response.body).to eq('{"etag":"123456"}')
      expect(cache_spy).to have_received(:miss).with('123456')
    end
  end
end