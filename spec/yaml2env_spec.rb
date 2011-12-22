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

  describe ".default_env?" do
    it 'should be defined' do
      Yaml2env.must_respond_to :default_env?
    end

    it 'should be true only if specified env equals default_env' do
      Yaml2env.default_env = 'development'

      Yaml2env.env = 'development'
      Yaml2env.default_env?.must_equal true

      Yaml2env.env = 'staging'
      Yaml2env.default_env?.must_equal false
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

    it "should detect environment for Rack-apps - 1st" do
      rack!(true)
      rails!(true)
      sinatra!(true)

      Yaml2env.root = nil
      lambda {
        Yaml2env.detect_root!
      }.must_be_silent
      Yaml2env.root.to_s.must_equal '/home/grimen/development/rack_app'
    end

    it "should detect environment for Rails-apps - 2nd" do
      rack!(false)
      rails!(true)
      sinatra!(true)

      Yaml2env.root = nil
      lambda {
        Yaml2env.detect_root!
      }.must_be_silent
      Yaml2env.root.to_s.must_equal '/home/grimen/development/rails_app'
    end

    it "should detect environment for Sinatra-apps - 3rd" do
      rack!(false)
      rails!(false)
      sinatra!(true)

      Yaml2env.root = nil
      lambda {
        Yaml2env.detect_root!
      }.must_be_silent
      Yaml2env.root.to_s.must_equal '/home/grimen/development/sinatra_app'
    end

    it 'should complain if no environment could be detected' do
      rack!(false)
      rails!(false)
      sinatra!(false)

      Yaml2env.root = nil
      assert_raises Yaml2env::DetectionFailedError do
        lambda {
          Yaml2env.detect_root!
        }.must_be_silent
      end
    end

    describe 'using file-pattern' do
      describe "that don't match any file in parent directories" do
        it "should detect root for Rack-apps - 1st" do
          rack!(true)
          rails!(true)
          sinatra!(true)

          Yaml2env.root = nil
          lambda {
            Yaml2env.detect_root!
          }.must_be_silent
          Yaml2env.root.to_s.must_equal '/home/grimen/development/rack_app'
        end

        it "should detect root for Rails-apps - 2nd" do
          rack!(false)
          rails!(true)
          sinatra!(true)

          Yaml2env.root = nil
          lambda {
            Yaml2env.detect_root!
          }.must_be_silent
          Yaml2env.root.to_s.must_equal '/home/grimen/development/rails_app'
        end

        it "should detect root for Sinatra-apps - 3rd" do
          rack!(false)
          rails!(false)
          sinatra!(true)

          Yaml2env.root = nil
          lambda {
            Yaml2env.detect_root!
          }.must_be_silent
          Yaml2env.root.to_s.must_equal '/home/grimen/development/sinatra_app'
        end

        it 'should complain if no root could be detected' do
          rack!(false)
          rails!(false)
          sinatra!(false)

          Yaml2env.root = nil
          assert_raises Yaml2env::DetectionFailedError do
            lambda {
              Yaml2env.detect_root! 'Ponies'
            }.must_be_silent
          end

          Yaml2env.root = nil
          assert_raises Yaml2env::DetectionFailedError do
            lambda {
              Yaml2env.detect_root! 'Fraggles'
            }.must_be_silent
          end

          Yaml2env.root = nil
          assert_raises Yaml2env::DetectionFailedError do
            lambda {
              Yaml2env.detect_root! 'Ponies', 'Fraggles'
            }.must_be_silent
          end

          Yaml2env.root = nil
          assert_raises Yaml2env::DetectionFailedError do
            lambda {
              Yaml2env.detect_root! %r/Ponies|Fraggles/
            }.must_be_silent
          end

          Yaml2env.root = nil
          assert_raises Yaml2env::DetectionFailedError do
            lambda {
              Yaml2env.detect_root! %r/^Ponies.*/
            }.must_be_silent
          end
        end

        it "should raise error unless arguments is either: one ore many strings, or regular expression" do
          rack!(false)
          rails!(false)
          sinatra!(false)

          Yaml2env.root = nil
          assert_raises Yaml2env::ArgumentError do
            lambda {
              Yaml2env.detect_root! %r/Ponies/, %r/Fraggles/
            }.must_be_silent
          end
        end
      end

      describe "that match any file in parent directories" do
        it "should detect root for Rack-apps - 1st" do
          rack!(true)
          rails!(true)
          sinatra!(true)

          Yaml2env.root = nil
          lambda {
            Yaml2env.detect_root!
          }.must_be_silent
          Yaml2env.root.to_s.must_equal '/home/grimen/development/rack_app'
        end

        it "should detect root for Rails-apps - 2nd" do
          rack!(false)
          rails!(true)
          sinatra!(true)

          Yaml2env.root = nil
          lambda {
            Yaml2env.detect_root!
          }.must_be_silent
          Yaml2env.root.to_s.must_equal '/home/grimen/development/rails_app'
        end

        it "should detect root for Sinatra-apps - 3rd" do
          rack!(false)
          rails!(false)
          sinatra!(true)

          Yaml2env.root = nil
          lambda {
            Yaml2env.detect_root!
          }.must_be_silent
          Yaml2env.root.to_s.must_equal '/home/grimen/development/sinatra_app'
        end

        it 'should detect root where the file was found' do
          rack!(false)
          rails!(false)
          sinatra!(false)

          spec_root = File.expand_path('..', __FILE__)

          Yaml2env.root = nil
          lambda {
            Yaml2env.detect_root! 'Gemfile'
          }.must_output <<-STDOUT
[Yaml2env] INFO: Detection of Yaml2env.root starting in: /Users/grimen/Dropbox/Development/projects/yaml2env/spec
[Yaml2env] INFO: Detection successful: Yaml2env.root = /Users/grimen/Dropbox/Development/projects/yaml2env (match: \"Gemfile\" =~ /^Gemfile$/)
          STDOUT
          Yaml2env.root.to_s.must_equal File.expand_path('..', spec_root)

          Yaml2env.root = nil
          lambda {
            Yaml2env.detect_root! 'Rakefile'
          }.must_output <<-STDOUT
[Yaml2env] INFO: Detection of Yaml2env.root starting in: /Users/grimen/Dropbox/Development/projects/yaml2env/spec
[Yaml2env] INFO: Detection successful: Yaml2env.root = /Users/grimen/Dropbox/Development/projects/yaml2env (match: \"Rakefile\" =~ /^Rakefile$/)
          STDOUT
          Yaml2env.root.to_s.must_equal File.expand_path('..', spec_root)

          Yaml2env.root = nil
          lambda {
            Yaml2env.detect_root! 'Gemfile', 'Rakefile'
          }.must_output <<-STDOUT
[Yaml2env] INFO: Detection of Yaml2env.root starting in: /Users/grimen/Dropbox/Development/projects/yaml2env/spec
[Yaml2env] INFO: Detection successful: Yaml2env.root = /Users/grimen/Dropbox/Development/projects/yaml2env (match: \"Gemfile\" =~ /^Gemfile|Rakefile$/)
          STDOUT
          Yaml2env.root.to_s.must_equal File.expand_path('..', spec_root)

          Yaml2env.root = nil
          lambda {
            Yaml2env.detect_root! 'Gemfile', 'Ponies'
          }.must_output <<-STDOUT
[Yaml2env] INFO: Detection of Yaml2env.root starting in: /Users/grimen/Dropbox/Development/projects/yaml2env/spec
[Yaml2env] INFO: Detection successful: Yaml2env.root = /Users/grimen/Dropbox/Development/projects/yaml2env (match: \"Gemfile\" =~ /^Gemfile|Ponies$/)
          STDOUT
          Yaml2env.root.to_s.must_equal File.expand_path('..', spec_root)

          Yaml2env.root = nil
          lambda {
            Yaml2env.detect_root! %r/Gemfile|Ponies/
          }.must_output <<-STDOUT
[Yaml2env] INFO: Detection of Yaml2env.root starting in: /Users/grimen/Dropbox/Development/projects/yaml2env/spec
[Yaml2env] INFO: Detection successful: Yaml2env.root = /Users/grimen/Dropbox/Development/projects/yaml2env (match: \"Gemfile\" =~ /Gemfile|Ponies/)
          STDOUT
          Yaml2env.root.to_s.must_equal File.expand_path('..', spec_root)

          Yaml2env.root = nil
          lambda {
            Yaml2env.detect_root! %r/^Gemfile.*/
          }.must_output <<-STDOUT
[Yaml2env] INFO: Detection of Yaml2env.root starting in: /Users/grimen/Dropbox/Development/projects/yaml2env/spec
[Yaml2env] INFO: Detection successful: Yaml2env.root = /Users/grimen/Dropbox/Development/projects/yaml2env (match: \"Gemfile\" =~ /^Gemfile.*/)
          STDOUT
          Yaml2env.root.to_s.must_equal File.expand_path('..', spec_root)
        end

        it "should raise error unless arguments is either: one ore many strings, or regular expression" do
          rack!(false)
          rails!(false)
          sinatra!(false)

          Yaml2env.root = nil
          assert_raises Yaml2env::ArgumentError do
            lambda {
              Yaml2env.detect_root! %r/Gemfile/, %r/Rackfile/
            }.must_be_silent
          end
        end
      end
    end
  end

  describe ".detect_env!" do
    before do
      Yaml2env.default_env = nil
    end

    it 'should be defined' do
      Yaml2env.must_respond_to :detect_env!
    end

    it "should detect environment for Rack-apps - 1st" do
      rack!(true)
      rails!(true)
      sinatra!(true)

      Yaml2env.env = nil
      Yaml2env.detect_env!
      Yaml2env.env.must_equal 'rack_env'
    end

    it "should detect environment for Rails-apps - 2nd" do
      rack!(false)
      rails!(true)
      sinatra!(true)

      Yaml2env.env = nil
      Yaml2env.detect_env!
      Yaml2env.env.must_equal 'rails_env'
    end

    it "should detect environment for Sinatra-apps - 3rd" do
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
      # }.must_output "[Yaml2env] Already loaded: -- arguments: [\"fixtures/example.yml\", {:API_KEY=>\"api_key\", :API_SECRET=>\"api_secret\"}])\n"
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

  describe ".log_env" do
    before do
      Yaml2env.default_env = nil
    end

    it 'should be defined' do
      Yaml2env.must_respond_to :log_env
    end

    it 'should log env value' do
      Yaml2env.env = nil
      lambda {
        Yaml2env.log_env
      }.must_output %{:: Yaml2env.env = nil\n}

      Yaml2env.env = 'development'
      lambda {
        Yaml2env.log_env
      }.must_output %{:: Yaml2env.env = "development"\n}
    end

    it 'should show default env is used if this is the case' do
      Yaml2env.default_env = 'development'
      Yaml2env.env = 'development'
      lambda {
        Yaml2env.log_env
      }.must_output %{:: Yaml2env.env = "development" (default)\n}

      Yaml2env.default_env = 'development'
      Yaml2env.env = 'staging'
      lambda {
        Yaml2env.log_env
      }.must_output %{:: Yaml2env.env = "staging"\n}
    end
  end

  describe ".log_root" do
    it 'should be defined' do
      Yaml2env.must_respond_to :log_root
    end

    it 'should log root value' do
      Yaml2env.root = nil
      lambda {
        Yaml2env.log_root
      }.must_output %{:: Yaml2env.root = nil\n}

      Yaml2env.root = '/tmp/path'
      lambda {
        Yaml2env.log_root
      }.must_output %{:: Yaml2env.root = "/tmp/path"\n}
    end
  end

  describe ".log_values" do
    it 'should be defined' do
      Yaml2env.must_respond_to :log_values
    end

    it 'should log ENV values' do
      with_constants :ENV => {"API_SECRET" => "PRODUCTION_SECRET", "API_KEY" => "PRODUCTION_KEY"} do
        lambda {
          Yaml2env.log_values
        }.must_output %{:: ENV = \"API_KEY\" => \"PRODUCTION_KEY\", \"API_SECRET\" => \"PRODUCTION_SECRET\"\n}
      end
    end

    it 'should log ENV values for specified key(s)' do
      with_constants :ENV => {"API_SECRET" => "PRODUCTION_SECRET", "API_KEY" => "PRODUCTION_KEY"} do
        lambda {
          Yaml2env.log_values 'API_KEY'
        }.must_output %{:: ENV = \"API_KEY\" => \"PRODUCTION_KEY\"\n}

        lambda {
          Yaml2env.log_values 'API_KEY', 'API_SECRET', 'BOGUS'
        }.must_output %{:: ENV = \"API_KEY\" => \"PRODUCTION_KEY\", \"API_SECRET\" => \"PRODUCTION_SECRET\"\n}
      end
    end

    it 'should log ENV values for specified key expression' do
      with_constants :ENV => {"API_SECRET" => "PRODUCTION_SECRET", "API_KEY" => "PRODUCTION_KEY"} do
        lambda {
          Yaml2env.log_values /API_KEY/
        }.must_output %{:: ENV = \"API_KEY\" => \"PRODUCTION_KEY\"\n}

        lambda {
          Yaml2env.log_values /API_KEY|API_SECRET|BOGUS/
        }.must_output %{:: ENV = \"API_KEY\" => \"PRODUCTION_KEY\", \"API_SECRET\" => \"PRODUCTION_SECRET\"\n}
      end
    end
  end

  describe ".assert_keys!" do
    before do
      Yaml2env.root = File.dirname(__FILE__)
      Yaml2env.env = 'development'
      Yaml2env.logger = nil # ::Logger.new(::STDOUT)
    end

    it 'should be defined' do
      Yaml2env.must_respond_to :assert_keys!
    end

    it 'should raise error if no arguments are specified' do
      lambda {
        Yaml2env.assert_keys!
      }.must_raise Yaml2env::ArgumentError
    end

    it 'should raise error if specified keys are not loaded into ENV' do
      Yaml2env.load 'fixtures/example.yml', {:API_KEY_6 => 'api_key', :API_SECRET_6 => 'api_secret'}

      lambda {
        Yaml2env.assert_keys! :BOGUS
      }.must_raise Yaml2env::MissingConfigKeyError

      lambda {
        Yaml2env.assert_keys! :BOGUS, :BOGUS_2
      }.must_raise Yaml2env::MissingConfigKeyError
    end

    it 'should not raise error if specified keys are loaded into ENV' do
      Yaml2env.load 'fixtures/example.yml', {:API_KEY_6 => 'api_key', :API_SECRET_6 => 'api_secret'}

      lambda {
        Yaml2env.assert_keys! :API_KEY_6
      }.must_be_silent

      lambda {
        Yaml2env.assert_keys! :API_KEY_6, :API_SECRET_6
      }.must_be_silent
    end
  end

  describe ".assert_keys" do
    before do
      Yaml2env.root = File.dirname(__FILE__)
      Yaml2env.env = 'development'
      Yaml2env.logger = nil # ::Logger.new(::STDOUT)
    end

    it 'should be defined' do
      Yaml2env.must_respond_to :assert_keys
    end

    it 'should raise error if no arguments are specified' do
      lambda {
        Yaml2env.assert_keys
      }.must_raise Yaml2env::ArgumentError
    end

    it 'should log warning if specified keys are not loaded into ENV' do
      Yaml2env.load 'fixtures/example.yml', {:API_KEY_5 => 'api_key', :API_SECRET_5 => 'api_secret'}

      lambda {
        Yaml2env.assert_keys :BOGUS
      }.must_output %{[Yaml2env] WARN: Assertion failed, no such ENV-keys loaded: \"BOGUS\"\n}

      lambda {
        Yaml2env.assert_keys :BOGUS, :BOGUS_2
      }.must_output %{[Yaml2env] WARN: Assertion failed, no such ENV-keys loaded: \"BOGUS\", \"BOGUS_2\"\n}
    end

    it 'should not log warning if specified keys are loaded into ENV' do
      Yaml2env.load 'fixtures/example.yml', {:API_KEY_5 => 'api_key', :API_SECRET_5 => 'api_secret'}

      lambda {
        Yaml2env.assert_keys :API_KEY_5
      }.must_be_silent

      lambda {
        Yaml2env.assert_keys :API_KEY_5, :API_SECRET_5
      }.must_be_silent
    end
  end

  describe ".assert_values!" do
    before do
      Yaml2env.root = File.dirname(__FILE__)
      Yaml2env.env = 'development'
      Yaml2env.logger = nil # ::Logger.new(::STDOUT)
    end

    it 'should be defined' do
      Yaml2env.must_respond_to :assert_values!
    end

    it 'should raise error if no hash is specified' do
      lambda {
        Yaml2env.assert_values!
      }.must_raise ArgumentError

      lambda {
        Yaml2env.assert_values!({})
      }.must_raise Yaml2env::ArgumentError

      lambda {
        Yaml2env.assert_values! :API_KEY_4
      }.must_raise Yaml2env::ArgumentError
    end

    it 'should raise error if specified hash values are not regular expression values' do
      lambda {
        Yaml2env.assert_values! :API_KEY_4 => 'DEVELOPMENT_KEY'
      }.must_raise Yaml2env::ArgumentError

      lambda {
        Yaml2env.assert_values! :API_KEY_4 => 'DEVELOPMENT_KEY', :API_SECRET_4 => /[A-Z]+/
      }.must_raise Yaml2env::ArgumentError
    end

    it 'should raise error if specified keys with - based on the expression - valid values are not loaded into ENV' do
      Yaml2env.load 'fixtures/example.yml', {:API_KEY_4 => 'api_key', :API_SECRET_4 => 'api_secret'}

      lambda {
        Yaml2env.assert_values! :API_KEY_4 => /[a-z]+/
      }.must_raise Yaml2env::InvalidConfigValueError

      lambda {
        Yaml2env.assert_values! :API_KEY_4 => /[a-z]+/, :API_SECRET_4 => /[A-Z]+/
      }.must_raise Yaml2env::InvalidConfigValueError

      lambda {
        Yaml2env.assert_values! :API_KEY_4 => /[a-z]+/, :API_SECRET_4 => /[a-z]+/
      }.must_raise Yaml2env::InvalidConfigValueError
    end

    it 'should not raise error if specified keys with - based on the expression - valid values are loaded into ENV' do
      Yaml2env.load 'fixtures/example.yml', {:API_KEY_4 => 'api_key', :API_SECRET_4 => 'api_secret'}

      lambda {
        Yaml2env.assert_values! :API_KEY_4 => /[A-Z]+/
      }.must_be_silent

      lambda {
        Yaml2env.assert_values! :API_KEY_4 => /[A-Z]+/, :API_SECRET_4 => /[A-Z]+/
      }.must_be_silent
    end
  end

  describe ".assert_values" do
    before do
      Yaml2env.root = File.dirname(__FILE__)
      Yaml2env.env = 'development'
      Yaml2env.logger = nil # ::Logger.new(::STDOUT)
    end

    it 'should be defined' do
      Yaml2env.must_respond_to :assert_values
    end

    it 'should raise error if no hash is specified' do
      lambda {
        Yaml2env.assert_values
      }.must_raise ArgumentError

      lambda {
        Yaml2env.assert_values({})
      }.must_raise Yaml2env::ArgumentError

      lambda {
        Yaml2env.assert_values :API_KEY_2
      }.must_raise Yaml2env::ArgumentError
    end

    it 'should raise error if specified hash values are not regular expression values' do
      lambda {
        Yaml2env.assert_values :API_KEY_2 => 'DEVELOPMENT_KEY'
      }.must_raise Yaml2env::ArgumentError

      lambda {
        Yaml2env.assert_values :API_KEY_2 => 'DEVELOPMENT_KEY', :API_SECRET_2 => /[A-Z]+/
      }.must_raise Yaml2env::ArgumentError
    end

    it 'should log warning if specified keys with - based on the expression - valid values are not loaded into ENV' do
      Yaml2env.load 'fixtures/example.yml', {:API_KEY_2 => 'api_key', :API_SECRET_2 => 'api_secret'}

      lambda {
        Yaml2env.assert_values :API_KEY_2 => /[a-z]+/
      }.must_output %{[Yaml2env] WARN: Assertion failed, invalid values: \"API_KEY_2\" => /[a-z]+/\n}

      lambda {
        Yaml2env.assert_values :API_KEY_2 => /[a-z]+/, :API_SECRET_2 => /[A-Z]+/
      }.must_output %{[Yaml2env] WARN: Assertion failed, invalid values: \"API_KEY_2\" => /[a-z]+/, \"API_SECRET_2\" => /[A-Z]+/\n}

      lambda {
        Yaml2env.assert_values :API_KEY_2 => /[a-z]+/, :API_SECRET_2 => /[a-z]+/
      }.must_output %{[Yaml2env] WARN: Assertion failed, invalid values: \"API_KEY_2\" => /[a-z]+/, \"API_SECRET_2\" => /[a-z]+/\n}
    end

    it 'should not log warning if specified keys with - based on the expression - valid values are loaded into ENV' do
      Yaml2env.load 'fixtures/example.yml', {:API_KEY_3 => 'api_key', :API_SECRET_3 => 'api_secret'}

      lambda {
        Yaml2env.assert_values :API_KEY_3 => /[A-Z]+/
      }.must_be_silent

      lambda {
        Yaml2env.assert_values :API_KEY_3 => /[A-Z]+/, :API_SECRET_3 => /[A-Z]+/
      }.must_be_silent
    end
  end

end