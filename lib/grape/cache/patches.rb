require 'grape'

module Grape
  class Endpoint
    private
    def run(env)
      @env = env
      @header = {}

      @request = Grape::Request.new(env)
      @params = @request.params
      @headers = @request.headers

      cookies.read(@request)

      self.class.before_each.call(self) if self.class.before_each

      run_filters befores

      # Inject our cache check
      options[:route_options][:cache] && options[:route_options][:cache].validate_cache(self, env['grape.cache'])

      run_filters before_validations

      # Retrieve validations from this namespace and all parent namespaces.
      validation_errors = []

      # require 'pry-byebug'; binding.pry

      route_setting(:saved_validations).each do |validator|
        begin
          validator.validate!(params)
        rescue Grape::Exceptions::Validation => e
          validation_errors << e
        end
      end

      if validation_errors.any?
        raise Grape::Exceptions::ValidationErrors, errors: validation_errors
      end

      run_filters after_validations

      response_text = @block ? @block.call(self) : nil
      run_filters afters
      cookies.write(header)

      [status, header, [body || response_text]]
    end
  end
end