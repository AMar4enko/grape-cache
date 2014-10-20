require 'spec_helper'

describe Grape::Cache do
  before do
    @backend = backend = Class.new(Grape::Cache::Backend::Memory) do
      public :storage
    end.new

    @grape_app = grape_app = Class.new(Grape::API) do
      version 'v1', using: :accept_version_header
      cache expire_after: 5.seconds do
      end
      get :index do

      end
    end

    @app = Rack::Builder.new do
      use Grape::Cache::Middleware, backend: backend
      run grape_app
    end.to_app
  end

  let :backend do
    @backend
  end

  def app
    @app
  end

  it 'store app result into backend' do
    allow(backend).to receive(:store).and_call_original
    get '/index'
    expect(backend).to have_received(:store)
  end

  describe 'modyfing cache key contents' do
    before do
      @grape_app.cache expire_after: 10.minutes do
        cache_key {|key_hash|
          key_hash[:header] = headers['My-Test']
          key_hash
        }
      end
      @grape_app.params do
        requires :n, type: Integer
      end
      @grape_app.get(:cache_key) do
        {test_key: 'test_value'}
      end
    end
    it 'alter cache key with cache_key block' do
       get '/cache_key.json?n=1',{},{'HTTP_MY_TEST' => 1}
       expect(last_response.status).to eq(200)
       get '/cache_key.json?n=1',{},{'HTTP_MY_TEST' => 1, 'HTTP_IF_MODIFIED_SINCE' => Time.now.httpdate}
       expect(last_response.status).to eq(304)
       get '/cache_key.json?n=1',{},{'HTTP_MY_TEST' => 1, 'HTTP_IF_MODIFIED_SINCE' => 700.seconds.from_now.httpdate}
       expect(last_response.status).to eq(200)
    end
  end
end