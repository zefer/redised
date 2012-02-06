require 'redis/namespace'
# Redised allows for the common patter of module access to redis, when included
# a .redis and .redis= method are provided
#
# Partially ganked from resque
module Redised

  def self.redis_connection(params)
    @redis_connections ||= {}
    @redis_connections[params] ||= Redis.new(params)
  end

  def self.included(klass)

    klass.module_eval do
      def self.redised_config
        if @_redised_config_path
          @_redised_config ||= YAML.load_file(@_redised_config_path)
        end
      end

      def self.redised_config_path
        @_redised_config_path
      end

      def self.redised_config_path=(new_path)
        @_redised_config_path = new_path
        @_redis = nil
        @_redised_config = nil
      end

      def self.redised_env
        @_redised_env ||= ENV['RAILS_ENV'] || ENV['RACK_ENV'] || nil
      end

      def self.redised_env=(new_env)
        @_redised_env = new_env
        @_redis = nil
        @_redised_config = nil
      end

      # Accepts:
      #   1. A 'hostname:port' string
      #   2. A 'hostname:port:db' string (to select the Redis db)
      #   3. A 'hostname:port/namespace' string (to set the Redis namespace)
      #   4. A redis URL string 'redis://host:port'
      #   5. An instance of `Redis`, `Redis::Client`, `Redis::DistRedis`,
      #      or `Redis::Namespace`.
      def self.redis=(server)
        if server.respond_to? :split

          if server =~ /redis\:\/\//
            conn = ::Redised.redis_connection(:url => server)
          else
            server, namespace = server.split('/', 2)
            host, port, db = server.split(':')
            conn = ::Redised.redis_connection(:host => host, :port => port,
                              :thread_safe => true, :db => db)
          end

          @_redis = namespace ? Redis::Namespace.new(namespace, :redis => conn) : conn
        else
          @_redis = server
        end
      end

      def self.redised_namespace(new_name = nil)
        new_name ? @_namespace = new_name : @_namespace
      end

      # Returns the current Redis connection. If none has been created, will
      # create a new one.
      def self.redis
        return @_redis if @_redis
        if redised_config
          self.redis = if redised_namespace
            redised_config[redised_namespace][redised_env]
          else
            redised_config[redised_env]
          end
        end
        @_redis
      rescue NoMethodError => e
        raise("There was a problem setting up your redis for redised_namespace #{redised_namespace} (from file #{@_redised_config_path}): #{e}")
      end
    end

  end

end
