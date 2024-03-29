require 'redis/namespace'
# Redised allows for the common patter of module access to redis, when included
# a .redis and .redis= method are provided
module Redised
  VERSION = '0.2.0'

  # Get a reusable connection based on a set of params. The
  # params are the same as the options you pass to `Redis.new`
  #
  # This ensures that an app doesnt try to open multiple connections
  # to the same redis server.
  def self.redis_connection(params)
    @_redis_connections ||= {}
    @_redis_connections[params] ||= Redis.new(params)
  end

  # Load/parse the YAML config setup at `redised_config_path`.
  # If no config is setup, returns nil
  #
  # Configs are in the format:
  #
  #     ---
  #     namespace:
  #       env: url
  #
  def self.redised_config
    if @_redised_config_path
      @_redised_config ||= YAML.load_file(@_redised_config_path)
    end
  end

  # Return the config path for the YAML config.
  def self.redised_config_path
    @_redised_config_path
  end

  # Set the config path to load from.
  def self.redised_config_path=(new_path)
    @_redised_config_path = new_path
    @_redised_config = nil
  end

  def self.redised_env
    @_redised_env ||= ENV['RAILS_ENV'] || ENV['RACK_ENV'] || nil
  end

  def self.redised_env=(new_env)
    @_redised_env = new_env
    @_redised_config = nil
  end

  def self.included(klass)

    klass.module_eval do

      # Accepts:
      #   1. A 'hostname:port' string
      #   2. A 'hostname:port:db' string (to select the Redis db)
      #   3. A 'hostname:port/namespace' string (to set the Redis namespace)
      #   4. A redis URL string 'redis://host:port'
      #   5. An instance of `Redis`, `Redis::Client`, `Redis::DistRedis`,
      #      or `Redis::Namespace`.
      #   6. A 'hostname:port:db:password' string (to select the Redis db & a password)
      def self.redis=(server)
        if server.respond_to? :split

          if server =~ /redis\:\/\//
            conn = ::Redised.redis_connection(:url => server)
          else
            server, namespace = server.split('/', 2)
            host, port, db, password = server.split(':')
            conn = ::Redised.redis_connection({
                :host => host,
                :port => port,
                :thread_safe => true,
                :db => db,
                :password => password
            })
          end

          @_redis = namespace ? Redis::Namespace.new(namespace, :redis => conn) : conn
        else
          @_redis = server
        end
      end

      def self.redised_namespace(new_name = nil)
        if new_name
          @_namespace = new_name
          @_redis = nil
        else
          @_namespace
        end
      end

      # Returns the current Redis connection. If none has been created, will
      # create a new one.
      def self.redis
        return @_redis if @_redis
        if ::Redised.redised_config
          self.redis = if redised_namespace
            ::Redised.redised_config[redised_namespace][::Redised.redised_env]
          else
            ::Redised.redised_config[::Redis.redised_env]
          end
        else
          self.redis = 'localhost:6379'
        end
        @_redis
      rescue NoMethodError => e
        raise("There was a problem setting up your redis for redised_namespace #{redised_namespace} (from file #{@_redised_config_path}): #{e}")
      end

      def redis
        self.class.redis
      end
    end

  end

end
