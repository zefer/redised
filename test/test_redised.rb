require 'helper'

class TestRedised < Test::Unit::TestCase

  class RedisedClass
    include Redised

    redised_namespace 'mynamespace'
  end

  class OtherRedisedClass
    include Redised
  end

  context "Redised" do
    setup do
      @env_config_path = File.join(File.dirname(__FILE__), 'env_redised_config.yml')
    end

    should "be able to assign the redised_config_path" do
      RedisedClass.redised_config_path = @env_config_path
      assert_equal @env_config_path, RedisedClass.redised_config_path
      assert RedisedClass.redised_config['mynamespace']
    end

    should "not have a default path" do
      assert_nil OtherRedisedClass.redised_config_path
    end

    should "pull default env from ENV" do
      ENV['RAILS_ENV'] = 'production'
      assert_equal 'production', RedisedClass.redised_env
    end

    should "allow for setting the env" do
      RedisedClass.redised_env = 'dev'
      assert_equal 'dev', RedisedClass.redised_env
    end

    should "have class level redis connection" do
      RedisedClass.redised_config_path = @env_config_path
      RedisedClass.redised_env = 'production'
      redis = RedisedClass.redis
      assert_kind_of Redis::Namespace, redis
    end

    should "parse redis connection with namespace" do
      RedisedClass.redis = 'localhost:5678:0/namespace'
      redis = RedisedClass.redis
      assert_equal 'localhost', redis.client.host
      assert_equal 5678, redis.client.port
      assert_equal 0, redis.client.db
      assert_equal 'namespace', redis.namespace
    end

  end

end
