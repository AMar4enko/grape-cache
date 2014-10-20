require 'spec_helper'

describe Grape::Cache::DSL do
  let :app do
    Class.new(Grape::API) do
    end
  end

  after(:each) { app.reset! }

  describe '.cache' do
    it 'adds .cache method into Grape::API' do
      expect{app.cache}.not_to raise_error
    end

    it 'saves cache configuration into route setting' do
      app.cache({})
      app.get(:test) {}
      expect(app.endpoints.first.options[:route_options][:cache]).not_to be_nil
    end

    it 'saves cache configuration only for next route' do
      app.cache({})
      app.get(:test1) {}
      app.get(:test2) {}
      expect(app.endpoints[1].options[:route_options][:cache]).to be_nil
    end

    it 'defines etag and last_modified methods inside cache block' do
      expect{app.cache do
        last_modified {}
        etag {}
      end}.not_to raise_error
    end
  end
end