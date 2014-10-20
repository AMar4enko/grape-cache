require 'spec_helper'

describe Grape::Cache do
  before do
    @backend = backend = Class.new(Grape::Cache::Backend::Memory) do
      public :storage
    end.new

    grape_app = Class.new(Grape::API) do
      cache for: 5.seconds do
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
end