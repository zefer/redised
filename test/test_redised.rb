require 'helper'

class TestRedised < Test::Unit::TestCase

  class RedisedClass
    module Redised
  end

  context "Redised" do
    setup do
      @env_config_path = File.join(File.dirname(__FILE__), 'env_redised_config.yml')
      @basic_config_path = File.join(File.dirname(__FILE__), 'basic_redised_config.yml')
    end

    should "be able to assign the redised_config_path" do
      new_path =
    end

  end

end
