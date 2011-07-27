require 'spec/spec_helper'

describe Yaml2env do

  before do
    @valid_config_filename = 'example.yml'
    @valid_config_path = File.join(File.dirname(__FILE__), 'fixtures', @valid_config_filename)
  end

  describe "::VERSION" do
    it 'should be defined' do
      defined?(::Yaml2env::VERSION)
    end

    it 'should be a valid version string (e.g. "0.0.1", or "0.0.1.rc1")' do
      valid_version_string = /^\d+\.\d+\.\d+/
      Yaml2env::VERSION.must_match valid_version_string
    end
  end

  describe "::LOADED_ENV" do
    it 'should be defined' do
      defined?(::Yaml2env::LOADED_ENV)
    end

    # it 'should be a empty hash' do
    #   Yaml2env::LOADED_ENV.must_equal({})
    # end
  end

  describe ".logger" do
    before do
      Yaml2env.defaults!
    end

    it 'should be defined' do
      Yaml2env.must_respond_to :logger
    end

    it 'should be a valid logger' do
      Yaml2env.logger.must_respond_to :info
      Yaml2env.logger.must_respond_to :debug
      Yaml2env.logger.must_respond_to :warn
    end

    it 'should be writable' do
      class MyLogger < Logger
      end
      custom_logger = MyLogger.new(::STDOUT)
      Yaml2env.logger = custom_logger
      Yaml2env.logger.must_equal custom_logger
    end
  end

  describe ".logger?" do
    it 'should be defined' do
      Yaml2env.must_respond_to :logger?
    end

    it 'should be a valid logger' do
      Yaml2env.logger = nil
      Yaml2env.logger?.must_equal false

      Yaml2env.logger = Logger.new(::STDOUT)
      Yaml2env.logger?.must_equal true
    end
  end

  describe ".root" do
    it 'should be defined' do
      Yaml2env.must_respond_to :root
    end

    it 'should be writable' do
      Yaml2env.root = "/tmp"
      Yaml2env.root.must_equal "/tmp"
    end
  end

  describe ".env" do
    it 'should be defined' do
      Yaml2env.must_respond_to :env
    end

    it 'should be writable' do
      Yaml2env.root = "/tmp"
      Yaml2env.root.must_equal "/tmp"
    end
  end

  describe ".configure" do
    it 'should be defined' do
      Yaml2env.must_respond_to :configure
    end

    it 'should be possible to change settings in a block' do
      Yaml2env.root = '/tmp/hello_world'
      Yaml2env.env = 'staging'
      Yaml2env.configure do |c|
        c.root = '/home/grimen/projects/hello_world'
        c.env = 'production'
      end
      Yaml2env.root.must_equal '/home/grimen/projects/hello_world'
      Yaml2env.env.must_equal 'production'
    end
  end

  describe ".detect_root!" do
    it 'should be defined' do
      Yaml2env.must_respond_to :detect_root!
    end

    it "should detect environment for Rack-apps - 1st" do
      rack!(true)
      rails!(true)
      sinatra!(true)

      Yaml2env.root = nil
      Yaml2env.detect_root!
      Yaml2env.root.must_equal '/home/grimen/development/rack-app'
    end

    it "should detect environment for Rails-apps - 2nd" do
      rack!(false)
      rails!(true)
      sinatra!(true)

      Yaml2env.root = nil
      Yaml2env.detect_root!
      Yaml2env.root.must_equal '/home/grimen/development/rails-app'
    end

    it "should detect environment for Sinatra-apps - 3rd" do
      rack!(false)
      rails!(false)
      sinatra!(true)

      Yaml2env.root = nil
      Yaml2env.detect_root!
      Yaml2env.root.must_equal '/home/grimen/development/sinatra-app'
    end

    it 'should complain if no environment could be detected' do
      rack!(false)
      rails!(false)
      sinatra!(false)

      Yaml2env.root = nil
      assert_raises Yaml2env::DetectionFailedError do
        Yaml2env.detect_root!
      end
    end
  end

  describe ".detect_env!" do
    it 'should be defined' do
      Yaml2env.must_respond_to :detect_env!
    end

    it "should detect environment for Rack-apps - 1st" do
      rack!(true)
      rails!(true)
      sinatra!(true)

      Yaml2env.env = nil
      Yaml2env.detect_env!
      Yaml2env.env.must_equal 'rack-env'
    end

    it "should detect environment for Rails-apps - 2nd" do
      rack!(false)
      rails!(true)
      sinatra!(true)

      Yaml2env.env = nil
      Yaml2env.detect_env!
      Yaml2env.env.must_equal 'rails-env'
    end

    it "should detect environment for Sinatra-apps - 3rd" do
      rack!(false)
      rails!(false)
      sinatra!(true)

      Yaml2env.env = nil
      Yaml2env.detect_env!
      Yaml2env.env.must_equal 'sinatra-env'
    end

    it 'should complain if no environment could be detected' do
      rack!(false)
      rails!(false)
      sinatra!(false)

      Yaml2env.env = nil
      assert_raises Yaml2env::DetectionFailedError do
        Yaml2env.detect_env!
      end
    end
  end

  describe "private/protected" do
    describe ".load_config" do
      it 'should be defined' do
        Yaml2env.must_respond_to :load_config
      end

      it 'should load config for all environments for a valid config YAML file without issues' do
        assert (config = Yaml2env.send(:load_config, @valid_config_path))
        config.must_be_kind_of Hash
        config.must_equal({
            "development"   => {"api_key"=>"DEVELOPMENT_KEY",   "api_secret"=>"DEVELOPMENT_SECRET"},
            "test"          => {"api_key"=>"TEST_KEY",          "api_secret"=>"TEST_SECRET"},
            "staging"       => {"api_key"=>"STAGING_KEY",       "api_secret"=>"STAGING_SECRET"},
            "production"    => {"api_key"=>"PRODUCTION_KEY",    "api_secret"=>"PRODUCTION_SECRET"},
            "nyan_cat_mode" => {"api_key"=>"NYAN_CAT_MODE_KEY", "api_secret"=>"NYAN_CAT_MODE_SECRET"}
          })
      end
    end

    describe ".load_config_for_env" do
      it 'should be defined' do
        Yaml2env.must_respond_to :load_config_for_env
      end

      it 'should load config for a valid environment for a valid config YAML file without issues' do
        env_config = Yaml2env.send(:load_config_for_env, @valid_config_path, 'development')
        env_config.must_equal({
            "api_key"=>"DEVELOPMENT_KEY",
            "api_secret"=>"DEVELOPMENT_SECRET"
          })

        env_config = Yaml2env.send(:load_config_for_env, @valid_config_path, 'test')
        env_config.must_equal({
            "api_key"=>"TEST_KEY", "api_secret"=>"TEST_SECRET"
          })

        env_config = Yaml2env.send(:load_config_for_env, @valid_config_path, 'staging')
        env_config.must_equal({
            "api_key"=>"STAGING_KEY", "api_secret"=>"STAGING_SECRET"
          })

        env_config = Yaml2env.send(:load_config_for_env, @valid_config_path, 'production')
        env_config.must_equal({
            "api_key"=>"PRODUCTION_KEY",
            "api_secret"=>"PRODUCTION_SECRET"
          })

        env_config = Yaml2env.send(:load_config_for_env, @valid_config_path, 'nyan_cat_mode')
        env_config.must_equal({
            "api_key"=>"NYAN_CAT_MODE_KEY",
            "api_secret"=>"NYAN_CAT_MODE_SECRET"
          })
      end

      it 'should not load config for a missing environment for a valid config YAML file without issues' do
        env_config = Yaml2env.send(:load_config_for_env, @valid_config_path, 'missing')
        env_config.must_equal(nil)
      end
    end
  end

  describe ".load" do
    before do
      Yaml2env.env = 'production'
      Yaml2env.root = File.dirname(__FILE__)
      Yaml2env.logger = nil
    end

    it 'should be defined' do
      Yaml2env.must_respond_to :load
    end

    it 'should throw error if specified config file that do not exist' do
      assert_raises Yaml2env::ConfigLoadingError do
        Yaml2env.load 'null.yml'
      end
    end

    it 'should not throw error if specified config file do exist' do
      assert Yaml2env.load('fixtures/example.yml')
    end

    it 'should throw error if a specified constant-key do not exist in the config file' do
      assert_raises Yaml2env::MissingConfigKeyError do
        Yaml2env.load 'fixtures/example.yml', {:API_KEY => 'bla'}
      end
    end

    it 'should not throw error if a specified constant-key do in fact exist in the config file' do
      assert Yaml2env.load 'fixtures/example.yml', {:API_KEY => 'api_key', :API_SECRET => 'api_secret'}
    end

    it 'should set - with Yaml2env - loaded ENV-values' do
      Yaml2env::LOADED_ENV.clear unless Yaml2env::LOADED_ENV.empty?
      Yaml2env.load 'fixtures/example.yml', {:API_KEY => 'api_key', :API_SECRET => 'api_secret'}
      Yaml2env::LOADED_ENV.must_equal({"API_SECRET" => "PRODUCTION_SECRET", "API_KEY" => "PRODUCTION_KEY"})
    end
  end

  protected

    def rack!(loaded)
      if loaded
        ::ENV['RACK_ROOT'] = '/home/grimen/development/rack-app'
        ::ENV['RACK_ENV'] = 'rack-env'
      else
        ::ENV['RACK_ROOT'] = nil
        ::ENV['RACK_ENV'] = nil
      end
    end

    def rails!(loaded)
      if loaded
        eval <<-EVAL
          unless defined?(::Rails)
            module Rails
              class << self
                attr_accessor :root, :env
              end
            end
          end
        EVAL
        Rails.root = '/home/grimen/development/rails-app'
        Rails.env = 'rails-env'
      else
        Object.send(:remove_const, :Rails) if defined?(::Rails)
      end
    end

    def sinatra!(loaded)
      if loaded
        eval <<-EVAL
        unless defined?(::Sinatra::Application)
          module Sinatra
            class Application
              class << self
                attr_accessor :root, :environment
              end
            end
          end
        end
        EVAL
        Sinatra::Application.root = '/home/grimen/development/sinatra-app'
        Sinatra::Application.environment = 'sinatra-env'
      else
        Object.send(:remove_const, :Sinatra) if defined?(::Sinatra::Application)
      end
    end

end