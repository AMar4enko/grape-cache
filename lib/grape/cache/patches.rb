# Updated for Grape 0.18

require 'grape'

module Grape
  class Endpoint
    protected

    def run
      ActiveSupport::Notifications.instrument('endpoint_run.grape', endpoint: self, env: env) do
        @header = {}

        @request = Grape::Request.new(env)
        @params = @request.params
        @headers = @request.headers

        cookies.read(@request)

        self.class.run_before_each(self)

        run_filters befores, :before

        #  Inject our cache check
        options[:route_options][:cache] &&
        options[:route_options][:cache].validate_cache(self, env['grape.cache'])

        if (allowed_methods = env[Grape::Env::GRAPE_ALLOWED_METHODS])
          raise Grape::Exceptions::MethodNotAllowed, header.merge('Allow' => allowed_methods) unless options?
          header 'Allow', allowed_methods
          response_object = ''
          status 204
        else
          run_filters before_validations, :before_validation
          run_validators validations, request
          run_filters after_validations, :after_validation
          response_object = @block ? @block.call(self) : nil
        end

        run_filters afters, :after
        cookies.write(header)

        # The Body commonly is an Array of Strings, the application instance itself, or a File-like object.
        response_object = file || [body || response_object]
        [status, header, response_object]
      end
    end # End run
  end
end
