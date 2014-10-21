# Grape::Cache

## Disclaimer: Gem is in early ALPHA
I built this gem for my own neeeds

## Installation

Add this line to your application's Gemfile:

    gem 'grape-cache'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install grape-cache

## Usage

### Middleware
Include Grape::Cache::Middleware in your app stack ABOVE your Grape app.
Example:

    use Grape::Cache::Middleware
    run Your::Grape::App

You can use Redis backend for caching middleware as follows:

    use Grape::Cache::Middleware, backend: Grape::Cache::Backend::Redis.new(your_redis_connection)

### Route caching
As simple as follows:

    cache do
      expire_after 5.seconds
      etag { #Your etag generation code }
      last_modified { #Your last_modified code here (expecting something what can receive #httpdate) }
    end
    get :test do

    end

#### Cache key
Response stored in specified backend with cache key generated using:

  * REQUEST_METHOD
  * PATH_INFO
  * Accept-Version header
  * hash built from route declared parameters

You can override hash source with cache_key block:

    params do
      requires company_id, type: Integer
      requires user_id, type: Integer
    end
    cache do
      cache_key do
        {user_id: params[:user_id]}
      end
    end

    get ':company_id/:user_id' do
    end

#### Cache expiration time
You can specify cache expiration time in two ways, class-eval or runtime-eval

    cache do
      expire_after 5.seconds # For class-eval specify time offset
      expire_after { 10.seconds.from_now } # For runtime-eval specify datetime
    end

Cache expiration time used in Cache-Control header for max-age section and for in-app cache expiration

## Useful info
All configuration blocks executed against current endpoint:

    etag do
      # Use params, env here
    end

_At least, they supposed to :D_

You can also use prepare block:

    cache do
      prepare { @user = User.find_by(params[:id]) }
      etag { @user.etag }
    end
    get :user do
      present @user
    end

Gem uses 64bit MurmurHash algo to build hashes

## Please, feel free to submit issues or feature requests

## Contributing

1. Fork it ( https://github.com/AlexYankee/grape-cache/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
