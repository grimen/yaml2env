require 'yaml'
require 'logger'
require 'active_support/string_inquirer'
require 'active_support/hash_with_indifferent_access'
require 'active_support/ordered_hash'
require 'active_support/core_ext/object/blank'
require 'pp'
begin
  require 'awesome_print'
rescue LoadError
  # optional
end

module Yaml2env

  autoload :VERSION,  'yaml2env/version'

  class Error < ::StandardError
  end

  class ArgumentError < ::ArgumentError
  end

  class DetectionFailedError < Error
  end

  class ConfigLoadingError < Error
  end

  class MissingConfigKeyError < Error
  end

  class InvalidConfigValueError < Error
  end

  class InvalidRootError < ArgumentError
  end

  class AlreadyLoadedError < Error
  end

  class HumanError < Error
  end

  # Hash tracking all of the loaded ENV-values via Yaml2env.load.
  LOADED_ENV = {}

  # Config root.
  # Default: (auto-detect if possible)
  @@root = nil

  # Config environment.
  # Default: (auto-detect if possible)
  @@env = nil

  # Logger to use for logging.
  # Default: +::Logger.new(::STDOUT)+
  @@logger = ::Logger.new(::STDOUT)

  # Loaded files and their values.
  @@loaded = {}

  # Default env.
  @@default_env = nil

  class << self

    [:default_env, :logger].each do |name|
      define_method name do
        class_variable_get :"@@#{name}"
      end
      define_method :"#{name}=" do |value|
        class_variable_set :"@@#{name}", value
      end
    end

    define_method :'root' do
      class_variable_get :'@@root'
    end
    define_method :'root=' do |value|
      if value.present?
        value = File.expand_path(value) rescue value
        value = Pathname.new(value) rescue value
        # FIXME: Makes sense, but need to rewrite specs somewhat - later.
        # if Dir.exists?(value)
        #   value = Pathname.new(value).expand_path
        # else
        #   raise InvalidRootError, "Trying to set Yaml2env.root to a path that don't exists: #{value.inspect}. Yaml2env.root must point to existing path."
        # end
      end
      class_variable_set :'@@root', value
    end

    define_method :'env' do
      class_variable_get :'@@env'
    end
    define_method :'env=' do |value|
      # FIXME: Specs "Yaml2env.env.must_equal" fails in really weird way with this line enabled.
      # value = ActiveSupport::StringInquirer.new(value.to_s) unless value.is_a?(ActiveSupport::StringInquirer)
      class_variable_set :'@@env', value
    end

    define_method :'loaded' do
      class_variable_get :'@@loaded'
    end

    alias :environment :env

    def defaults!
      @@root ||= nil
      @@env ||= nil
      @@logger ||= ::Logger.new(::STDOUT)
      @@loaded ||= {}
      @@default_env ||= nil
    end

    def configure
      yield self
    end

    def load!(config_path, required_keys = {}, optional_keys = {})
      self.detect_root!
      self.detect_env!

      config ||= {}

      begin
        unless File.exists?(config_path)
          config_path = File.expand_path(File.join(self.root, config_path)).to_s
        end
        config = self.load_config_for_env(config_path, self.env)
      rescue
        raise ConfigLoadingError, "Failed to load required config for environment '#{self.env}': #{config_path}"
      end

      # Merge required + optional keys.
      keys_values = optional_keys.merge(required_keys)
      loaded_key_values = ActiveSupport::OrderedHash.new

      # Stash found keys from the config into ENV.
      keys_values.each do |extected_env_key, extected_yaml_key|
        config_value = config[extected_yaml_key.to_s]
        ::Yaml2env::LOADED_ENV[extected_env_key.to_s] = ::ENV[extected_env_key.to_s] = config_value
        info ":: ENV[#{extected_env_key.inspect}] = #{::ENV[extected_env_key.to_s].inspect}"
      end

      self.loaded[config_path] = config

      # Raise error if any credentials are missing.
      required_keys.keys.each do |env_key|
        ::Yaml2env::LOADED_ENV[env_key.to_s] ||
          raise(MissingConfigKeyError, "ENV variable '#{env_key}' needs to be set. Query: #{keys_values.inspect}. Found: #{config.inspect}")
      end

      true
    end

    def load(config_path, required_keys = {}, optional_keys = {})
      args = [config_path, required_keys, optional_keys]

      begin
        self.load!(config_path, required_keys, optional_keys)
      rescue Error => e
        warn "[Yaml2env]: #{e} -- arguments: #{args.inspect})"
      end
      true
    end

    public # force public - we are overriding private Ruby method here, but should be all good in the hood. >:)

    def require!(config_path, required_keys = {}, optional_keys = {})
      self.detect_root!
      config_path = File.expand_path(File.join(self.root, config_path)).to_s
      raise AlreadyLoadedError, "Already loaded:" if self.loaded_files.include?(config_path)
      self.load!(config_path, required_keys, optional_keys)
    end

    def require(*args)
      begin
        self.require!(*args)
        true
      rescue AlreadyLoadedError => e
        false
      rescue Error => e
        warn "[Yaml2env]: #{e} -- arguments: #{args.inspect})"
        false
      end
    end

    def loaded_files
      self.loaded.keys
    end

    def loaded?(*constant_names)
      constant_names.all? { |cn| ::Yaml2env::LOADED_ENV.key?(cn.to_s) }
    end

    def detect_root!
      self.root ||= if ::ENV.key?('RACK_ROOT')
        ::ENV['RACK_ROOT']
      elsif defined?(::Rails)
        ::Rails.root
      elsif defined?(::Sinatra::Application)
        ::Sinatra::Application.root
      else
        raise DetectionFailedError, "Failed to auto-detect Yaml.root (config root). Specify root before loading any configs/initializers using Yaml2env, e.g. Yaml2env.root = '~/projects/my_app'."
      end
    end

    def detect_env!
      self.env ||= if ::ENV['RACK_ENV'].present?
        ::ENV['RACK_ENV']
      elsif defined?(::Rails)
        ::Rails.env
      elsif defined?(::Sinatra::Application)
        ::Sinatra::Application.environment
      elsif self.default_env.present?
        self.default_env
      else
        raise DetectionFailedError, "Failed to auto-detect Yaml2env.env (config environment). Specify environment before loading any configs/initializers using Yaml2env, e.g. Yaml2env.env = 'development'."
      end
    end

    def logger?
      self.logger.respond_to?(:info)
    end

    def root?
      self.root.present?
    end

    def env?(*args)
      if args.size > 0
        raise HumanError, "Seriously, what are you trying to do? *<:)" if args.size > 1 && args.count { |a| a.blank? } > 1
        args.any? do |arg|
          arg.is_a?(Regexp) ? self.env.to_s =~ arg : self.env.to_s == arg.to_s
        end
      else
        self.env.present?
      end
    end

    def default_env?
      self.env == self.default_env
    end

    def log_env
      value = self.env.inspect
      output = ":: Yaml2env.env = #{value}"
      output << " (default)" if self.default_env? && self.default_env.present?
      puts output
    end

    def log_root
      value = self.root.present? ? self.root.to_s.inspect : self.root.inspect
      output = ":: Yaml2env.root = #{value}"
      puts output
    end

    def log_values(*args)
      if args.blank?
        should_include = proc { true }
      elsif args.first.is_a?(Regexp)
        key_pattern = args.shift
        should_include = proc { |key| key =~ key_pattern }
      else
        should_include = proc { |key| args.any? { |key_string| key == key_string; }  }
      end
      key_values = {}
      ::ENV.keys.sort.each do |k,v|
        key_values[k] = ENV[k] if should_include.call(k)
      end
      print ":: ENV = "
      puts format_output key_values
    end

    def assert_keys!(*required_keys)
      raise ArgumentError, "Expected ENV-keys, but got: #{required_keys.inspect}" if required_keys.blank?
      raise ArgumentError, "Expected ENV-keys, but got: #{required_keys.inspect}" unless required_keys.first.is_a?(String) || required_keys.first.is_a?(Symbol)

      required_keys = required_keys.collect { |k| k.to_s }
      missing_keys = required_keys - ::ENV.keys

      if missing_keys.size == 0
        true
      else
        raise MissingConfigKeyError, "Assertion failed, no such ENV-keys loaded: #{missing_keys}"
      end
    end

    def assert_keys(*required_keys)
      begin
        self.assert_keys!(*required_keys)
        true
      rescue Error => e
        print "[Yaml2env] WARN: Assertion failed, no such ENV-keys loaded: "
        puts format_output required_keys
        false
      end
    end

    def assert_values!(key_values)
      raise ArgumentError, "Expected hash, but got: #{key_values.inspect}" unless key_values.is_a?(Hash) && key_values.present?
      raise ArgumentError, "Expected hash with string-regexp values, but got: #{key_values.inspect}" unless key_values.all? { |k, v| v.is_a?(Regexp) }

      self.assert_keys! *key_values.keys

      failed_assertions = {}

      key_values.each do |k, v|
        k = k.to_s
        failed_assertions[k] = ::ENV[k] unless ::ENV[k] =~ v
      end

      if failed_assertions.keys.size == 0
        true
      else
        raise InvalidConfigValueError, "Assertion failed, invalid values: #{failed_assertions}"
      end
    end

    def assert_values(key_values)
      begin
        self.assert_values!(key_values)
        true
      rescue Error => e
        print "[Yaml2env] WARN: Assertion failed, invalid values: "
        puts format_output key_values
        false
      end
    end

    protected

      # Work around helpers to make output specs pass on different Ruby version (ordered hash problem). Grrr...
      def format_output(array_or_hash)
        if array_or_hash.is_a?(Array)
          array_or_hash.collect(&:to_s).sort.collect { |k| "#{k.inspect}" }.join(", ")
        elsif array_or_hash.is_a?(Hash)
          array_or_hash = ActiveSupport::HashWithIndifferentAccess.new(array_or_hash)
          array_or_hash.keys.collect(&:to_s).sort.collect { |k| "#{k.inspect} => #{array_or_hash[k].inspect}" }.join(", ")
        end
      end

      def pretty(*args)
        begin
          ap *args
        rescue
          pp *args
        end
      end

      def info(message)
        self.logger.info message if self.logger?
        # puts message
      end

      # FIXME: Should show filepath for calle.
      def warn(message)
        self.logger.warn(message) if self.logger?
        # puts message
      end

      def load_config(config_file)
        YAML.load(File.open(config_file))
      end

      def load_config_for_env(config_file, env)
        config = self.load_config(config_file)
        config[env]
      end

  end

end
