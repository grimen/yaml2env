require 'spec_helper'

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
      Yaml2env.root.to_s.must_equal "/tmp"
    end

    it 'should be Pathname - respond to #join - if present' do
      Yaml2env.root = nil
      Yaml2env.root.must_be_kind_of NilClass
      Yaml2env.root.wont_respond_to :join

      Yaml2env.root = ""
      Yaml2env.root.must_be_kind_of String
      Yaml2env.root.wont_respond_to :join

      Yaml2env.root = "/tmp"
      Yaml2env.root.must_be_kind_of Pathname
      Yaml2env.root.must_respond_to :join
      Yaml2env.root.join('ponies').to_s.must_equal "/tmp/ponies"
    end

    # TODO: Need to alter other specs to get this work well - later.
    # it 'should not accept non-existing path - makes no sense' do
    #   lambda { Yaml2env.root = "/tmp/i_dont_exist" }.must_raise Yaml2env::InvalidRootError
    # end

    it 'should expand path automatically' do
      Yaml2env.root = "/tmp/path/../path/.."
      Yaml2env.root.to_s.must_equal "/tmp"
    end
  end

  describe ".root?" do
    it 'should be defined' do
      Yaml2env.must_respond_to :root?
    end

    it 'should return true if root is present, otherwise false' do
      Yaml2env.root = nil
      Yaml2env.root?.must_equal false

      Yaml2env.root = ""
      Yaml2env.root?.must_equal false

      Yaml2env.root = "/"
      Yaml2env.root?.must_equal true

      Yaml2env.root = "/path/to/project"
      Yaml2env.root?.must_equal true
    end
  end

  describe ".env" do
    it 'should be defined' do
      Yaml2env.must_respond_to :env
    end

    it 'should be writable' do
      Yaml2env.root = "/tmp"
      Yaml2env.root.to_s.must_equal "/tmp"
    end

    # FIXME: See TODO.
    it "should respond true/false for matching environment via method missing (a.k.a. string inquiry)" do
      skip

      Yaml2env.env.must_respond_to :development?
      Yaml2env.env.must_respond_to :staging?
      Yaml2env.env.must_respond_to :production?
      Yaml2env.env.must_respond_to :bogus?

      Yaml2env.env = nil
      Yaml2env.env.development?.must_equal false

      Yaml2env.env = ""
      Yaml2env.env.development?.must_equal false

      Yaml2env.env = "development"
      Yaml2env.env.development?.must_equal true
      Yaml2env.env.bogus?.must_equal false

      Yaml2env.env = "staging"
      Yaml2env.env.development?.must_equal false

      Yaml2env.env = "production"
      Yaml2env.env.production?.must_equal true
    end
  end

  describe ".env?" do
    it 'should be defined' do
      Yaml2env.must_respond_to :env?
    end

    describe "with no arguments" do
      it 'should return true if env is present, otherwise false' do
        Yaml2env.env = nil
        Yaml2env.env?.must_equal false

        Yaml2env.env = ""
        Yaml2env.env?.must_equal false

        Yaml2env.env = "development"
        Yaml2env.env?.must_equal true
      end
    end

    describe "with one argument" do
      # Stupid spec, but for the record...
      it 'nil/blank: should return true if env equals, otherwise false' do
        Yaml2env.env = nil
        Yaml2env.env?(nil).must_equal true
        Yaml2env.env?("").must_equal true

        Yaml2env.env = ""
        Yaml2env.env?(nil).must_equal true
        Yaml2env.env?("").must_equal true
      end

      it 'string: should return true if env equals, otherwise false' do
        Yaml2env.env = nil
        Yaml2env.env?("development").must_equal false

        Yaml2env.env = ""
        Yaml2env.env?("development").must_equal false

        Yaml2env.env = "development"
        Yaml2env.env?("development").must_equal true

        Yaml2env.env = "staging"
        Yaml2env.env?("development").must_equal false
      end

      it 'regexp: should return true if env matches, otherwise false' do
        Yaml2env.env = nil
        Yaml2env.env?(/development|staging/).must_equal false

        Yaml2env.env = ""
        Yaml2env.env?(/development|staging/).must_equal false

        Yaml2env.env = "development"
        Yaml2env.env?(/development|staging/).must_equal true

        Yaml2env.env = "staging"
        Yaml2env.env?(/development|staging/).must_equal true
      end
    end

    describe "with one argument" do
      # *<:)
      it 'nils/blanks: should return true if env equals, otherwise false' do
        Yaml2env.env = nil
        lambda { Yaml2env.env?(nil, nil) }.must_raise Yaml2env::HumanError
        lambda { Yaml2env.env?(nil, "") }.must_raise Yaml2env::HumanError
        lambda { Yaml2env.env?("", "") }.must_raise Yaml2env::HumanError

        Yaml2env.env = ""
        lambda { Yaml2env.env?(nil, nil) }.must_raise Yaml2env::HumanError
        lambda { Yaml2env.env?(nil, "") }.must_raise Yaml2env::HumanError
        lambda { Yaml2env.env?("", "") }.must_raise Yaml2env::HumanError
      end

      it 'strings: should return true if env equals, otherwise false' do
        Yaml2env.env = nil
        Yaml2env.env?("development", "staging").must_equal false

        Yaml2env.env = ""
        Yaml2env.env?("development", "staging").must_equal false

        Yaml2env.env = "development"
        Yaml2env.env?("development", "staging").must_equal true

        Yaml2env.env = "staging"
        Yaml2env.env?("development", "staging").must_equal true

        Yaml2env.env = "production"
        Yaml2env.env?("development", "staging").must_equal false
      end

      it 'regexpes: should return true if env matches, otherwise false' do
        Yaml2env.env = nil
        Yaml2env.env?(/development|staging/).must_equal false

        Yaml2env.env = ""
        Yaml2env.env?(/development|staging/).must_equal false

        Yaml2env.env = "development"
        Yaml2env.env?(/development|staging/).must_equal true

        Yaml2env.env = "staging"
        Yaml2env.env?(/development|staging/).must_equal true
      end
    end
  end

  describe ".default_env" do
    it 'should be defined' do
      Yaml2env.must_respond_to :default_env
    end

    it 'should be default value for Yaml2env.env if no value is set' do
      with_constants :ENV => {'RACK_ENV' => nil} do
        Yaml2env.default_env = 'development'
        Yaml2env.env = nil
        Yaml2env.detect_env!
        Yaml2env.env.must_equal 'development'

        Yaml2env.default_env = 'development'
        Yaml2env.env = 'staging'
        Yaml2env.detect_env!
        Yaml2env.env.must_equal 'staging'

        Yaml2env.default_env = nil
      end
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
      Yaml2env.root.to_s.must_equal '/home/grimen/projects/hello_world'
      Yaml2env.env.must_equal 'production'
    end
  end

  describe ".detect_root!" do
    it 'should be defined' do
      Yaml2env.must_respond_to :detect_root!
    end

    it "should detect environment for Rack_apps - 1st" do
      rack!(true)
      rails!(true)
      sinatra!(true)

      Yaml2env.root = nil
      Yaml2env.detect_root!
      Yaml2env.root.to_s.must_equal '/home/grimen/development/rack_app'
    end

    it "should detect environment for Rails_apps - 2nd" do
      rack!(false)
      rails!(true)
      sinatra!(true)

      Yaml2env.root = nil
      Yaml2env.detect_root!
      Yaml2env.root.to_s.must_equal '/home/grimen/development/rails_app'
    end

    it "should detect environment for Sinatra_apps - 3rd" do
      rack!(false)
      rails!(false)
      sinatra!(true)

      Yaml2env.root = nil
      Yaml2env.detect_root!
      Yaml2env.root.to_s.must_equal '/home/grimen/development/sinatra_app'
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

    it "should detect environment for Rack_apps - 1st" do
      rack!(true)
      rails!(true)
      sinatra!(true)

      Yaml2env.env = nil
      Yaml2env.detect_env!
      Yaml2env.env.must_equal 'rack_env'
    end

    it "should detect environment for Rails_apps - 2nd" do
      rack!(false)
      rails!(true)
      sinatra!(true)

      Yaml2env.env = nil
      Yaml2env.detect_env!
      Yaml2env.env.must_equal 'rails_env'
    end

    it "should detect environment for Sinatra_apps - 3rd" do
      rack!(false)
      rails!(false)
      sinatra!(true)

      Yaml2env.env = nil
      Yaml2env.detect_env!
      Yaml2env.env.must_equal 'sinatra_env'
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

  describe ".load!" do
    before do
      Yaml2env.env = 'production'
      Yaml2env.root = File.dirname(__FILE__)
      Yaml2env.logger = nil
    end

    it 'should be defined' do
      Yaml2env.must_respond_to :load!
    end

    it 'should throw error if specified config file that do not exist' do
      assert_raises Yaml2env::ConfigLoadingError do
        Yaml2env.load! 'null.yml'
      end
    end

    it 'should not throw error if specified config file do exist' do
      assert Yaml2env.load!('fixtures/example.yml')
    end

    it 'should throw error if a specified constant-key do not exist in the config file' do
      assert_raises Yaml2env::MissingConfigKeyError do
        Yaml2env.load! 'fixtures/example.yml', {:API_KEY => 'bla'}
      end
    end

    it 'should not throw error if a specified constant-key do in fact exist in the config file' do
      assert Yaml2env.load! 'fixtures/example.yml', {:API_KEY => 'api_key', :API_SECRET => 'api_secret'}
    end

    it 'should set - with Yaml2env - loaded ENV-values' do
      Yaml2env::LOADED_ENV.clear unless Yaml2env::LOADED_ENV.empty?
      Yaml2env.load! 'fixtures/example.yml', {:API_KEY => 'api_key', :API_SECRET => 'api_secret'}
      Yaml2env::LOADED_ENV.must_equal({"API_SECRET" => "PRODUCTION_SECRET", "API_KEY" => "PRODUCTION_KEY"})
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

    it 'should at maximum log warning if specified config file that do not exist' do
      assert Yaml2env.load('null.yml')
    end

    it 'should not log warning or raise error if specified config file do exist' do
      assert Yaml2env.load('fixtures/example.yml')
    end

    it 'should at maximum log warning if a specified constant-key do not exist in the config file' do
      assert Yaml2env.load 'fixtures/example.yml', {:API_KEY => 'bla'}
    end

    it 'should not log warning or raise error if a specified constant-key do in fact exist in the config file' do
      assert Yaml2env.load 'fixtures/example.yml', {:API_KEY => 'api_key', :API_SECRET => 'api_secret'}
    end

    it 'should set - with Yaml2env - loaded ENV-values' do
      Yaml2env::LOADED_ENV.clear unless Yaml2env::LOADED_ENV.empty?
      Yaml2env.load 'fixtures/example.yml', {:API_KEY => 'api_key', :API_SECRET => 'api_secret'}
      Yaml2env::LOADED_ENV.must_equal({"API_SECRET" => "PRODUCTION_SECRET", "API_KEY" => "PRODUCTION_KEY"})
    end
  end

  describe ".require!" do
    before do
      Yaml2env.env = 'production'
      Yaml2env.root = File.dirname(__FILE__)
      Yaml2env.logger = nil # ::Logger.new(::STDOUT)
      Yaml2env.stubs(:loaded).returns({})
    end

    it 'should be defined' do
      Yaml2env.must_respond_to :require!
    end

    it 'should throw error if specified config file that do not exist' do
      proc { Yaml2env.require! 'null.yml' }.must_raise Yaml2env::ConfigLoadingError
    end

    it 'should not throw error if specified config file do exist' do
      proc { Yaml2env.require!('fixtures/example.yml') }.must_be_silent
    end

    it 'should throw error if a specified constant-key do not exist in the config file' do
      proc {
        Yaml2env.require! 'fixtures/example.yml', {:API_KEY => 'bla'}
      }.must_raise Yaml2env::MissingConfigKeyError
    end

    it 'should not throw error if a specified constant-key do in fact exist in the config file' do
      assert Yaml2env.require! 'fixtures/example.yml', {:API_KEY => 'api_key', :API_SECRET => 'api_secret'}
    end

    it 'should set - with Yaml2env - required ENV-values' do
      Yaml2env::LOADED_ENV.clear unless Yaml2env::LOADED_ENV.empty?
      Yaml2env.require! 'fixtures/example.yml', {:API_KEY => 'api_key', :API_SECRET => 'api_secret'}
      Yaml2env::LOADED_ENV.must_equal({"API_SECRET" => "PRODUCTION_SECRET", "API_KEY" => "PRODUCTION_KEY"})
    end

    it "should only load specified file if it has not been loaded already - like Ruby require vs. load" do
      assert Yaml2env.require! 'fixtures/example.yml', {:API_KEY => 'api_key', :API_SECRET => 'api_secret'}
      lambda {
        Yaml2env.require! 'fixtures/example.yml', {:API_KEY => 'api_key', :API_SECRET => 'api_secret'}
      }.must_raise Yaml2env::AlreadyLoadedError
      assert Yaml2env.require! 'fixtures/example2.yml', {:API_KEY => 'api_key', :API_SECRET => 'api_secret'}
    end
  end

  describe ".require" do
    before do
      Yaml2env.env = 'production'
      Yaml2env.root = File.dirname(__FILE__)
      Yaml2env.logger = nil # ::Logger.new(::STDOUT)
      Yaml2env.stubs(:loaded).returns({})
    end

    it 'should be defined' do
      Yaml2env.must_respond_to :require
    end

    it 'should at maximum log warning if specified config file that do not exist' do
      proc { Yaml2env.require('null.yml') }.must_be_silent
    end

    it 'should not log warning or raise error if specified config file do exist' do
      proc { Yaml2env.require('fixtures/example.yml') }.must_be_silent
    end

    it 'should at maximum log warning if a specified constant-key do not exist in the config file' do
      proc { Yaml2env.require 'fixtures/example.yml', {:API_KEY => 'bla'} }.must_be_silent
    end

    it 'should not log warning or raise error if a specified constant-key do in fact exist in the config file' do
      proc {
        assert Yaml2env.require 'fixtures/example.yml', {:API_KEY => 'api_key', :API_SECRET => 'api_secret'}
      }.must_be_silent
    end

    it 'should set - with Yaml2env - requireed ENV-values' do
      Yaml2env::LOADED_ENV.clear unless Yaml2env::LOADED_ENV.empty?
      Yaml2env.require 'fixtures/example.yml', {:API_KEY => 'api_key', :API_SECRET => 'api_secret'}
      Yaml2env::LOADED_ENV.must_equal({"API_SECRET" => "PRODUCTION_SECRET", "API_KEY" => "PRODUCTION_KEY"})
    end

    it "should only load specified file if it has not been loaded already - like Ruby require vs. load" do
      Yaml2env.require('fixtures/example.yml', {:API_KEY => 'api_key', :API_SECRET => 'api_secret'}).must_equal true
      Yaml2env.require('fixtures/example.yml', {:API_KEY => 'api_key', :API_SECRET => 'api_secret'}).must_equal false
      Yaml2env.require('fixtures/example2.yml', {:API_KEY => 'api_key', :API_SECRET => 'api_secret'}).must_equal true

      # FIXME: How test output using Logger - only works with "puts", and also need to silence spec output. :P
      # args = ['fixtures/example.yml', {:API_KEY => 'api_key', :API_SECRET => 'api_secret'}]
      # lambda {
      #   Yaml2env.require *args
      # }.must_output "[Yaml2env]: Already loaded: -- arguments: [\"fixtures/example.yml\", {:API_KEY=>\"api_key\", :API_SECRET=>\"api_secret\"}])\n"
    end
  end

  describe ".loaded" do
    before do
      Yaml2env.env = 'production'
      Yaml2env.root = File.dirname(__FILE__)
      Yaml2env.logger = nil
    end

    it 'should be defined' do
      Yaml2env.must_respond_to :loaded
    end

    it 'should hold any loaded values - based on loaded filename as key' do
      key_1 = File.join(File.dirname(__FILE__), 'fixtures/example.yml')
      key_2 = File.join(File.dirname(__FILE__), 'fixtures/example2.yml')

      Yaml2env.load 'fixtures/example.yml', {:API_KEY => 'api_key', :API_SECRET => 'api_secret'}
      Yaml2env.loaded.keys.must_include key_1
      Yaml2env.loaded[key_1].must_equal({'api_key' => 'PRODUCTION_KEY', 'api_secret' => 'PRODUCTION_SECRET'})

      Yaml2env.load 'fixtures/example2.yml', {:API_KEY => 'api_key', :API_SECRET => 'api_secret'}
      Yaml2env.loaded.keys.must_include key_1
      Yaml2env.loaded.keys.must_include key_2
      Yaml2env.loaded[key_1].must_equal({'api_key' => 'PRODUCTION_KEY',   'api_secret' => 'PRODUCTION_SECRET'})
      Yaml2env.loaded[key_2].must_equal({'api_key' => 'PRODUCTION_KEY_2', 'api_secret' => 'PRODUCTION_SECRET_2'})
    end
  end

  describe ".loaded_files" do
    it 'should be defined' do
      Yaml2env.must_respond_to :loaded_files
    end

    it 'should return loaded files' do
      file_1 = File.join(File.dirname(__FILE__), 'fixtures/example.yml')
      file_2 = File.join(File.dirname(__FILE__), 'fixtures/example2.yml')

      Yaml2env.loaded_files.must_be_kind_of Array

      Yaml2env.load 'fixtures/example.yml'
      Yaml2env.loaded_files.must_include file_1

      Yaml2env.load 'fixtures/example2.yml'
      Yaml2env.loaded_files.must_include file_1, file_2
    end
  end

  describe ".loaded?" do
    before do
      Yaml2env::LOADED_ENV.clear unless Yaml2env::LOADED_ENV.empty?
    end

    it 'should be defined' do
      Yaml2env.must_respond_to :loaded?
    end

    describe "one argument" do
      it 'should return false if specified constant is not loaded into ENV' do
        Yaml2env.loaded?('API_KEY').must_equal false
      end

      it 'should return true if specified constant is loaded into ENV' do
        Yaml2env.load 'fixtures/example.yml', {:API_KEY => 'api_key', :API_SECRET => 'api_secret'}
        Yaml2env.loaded?('API_KEY').must_equal true
      end
    end

    describe "multiple arguments" do
      it 'should return false if none of the specified constants are not loaded into ENV' do
        Yaml2env.loaded?('API_KEY', 'API_SECRET').must_equal false
      end

      it 'should return false if any of the specified constants are not loaded into ENV' do
        Yaml2env.load 'fixtures/example.yml', {:API_KEY => 'api_key'}
        Yaml2env.loaded?('API_KEY', 'API_SECRET').must_equal false
      end

      it 'should return true if all specified constants are loaded into ENV' do
        Yaml2env.load 'fixtures/example.yml', {:API_KEY => 'api_key', :API_SECRET => 'api_secret'}
        Yaml2env.loaded?('API_KEY', 'API_SECRET').must_equal true
      end
    end
  end

end