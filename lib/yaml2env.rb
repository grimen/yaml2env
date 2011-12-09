require 'yaml'
require 'logger'
require 'active_support/string_inquirer'
require 'active_support/core_ext/object/blank'

module Yaml2env

  autoload :VERSION,  'yaml2env/version'

  class Error < ::StandardError
  end

  class DetectionFailedError < Error
  end

  class ConfigLoadingError < Error
  end

  class MissingConfigKeyError < Error
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

  class << self

    [:root, :env, :logger].each do |name|
      define_method name do
        class_variable_get "@@#{name}"
      end
      define_method "#{name}=" do |value|
        class_variable_set "@@#{name}", value
      end
    end

    alias :environment :env

    def defaults!
      @@root ||= nil
      @@env ||= nil
      @@logger ||= ::Logger.new(::STDOUT)
    end

    def configure
      yield self
    end

    def load!(config_path, required_keys = {}, optional_keys = {})
      self.detect_root!
      self.detect_env!

      config ||= {}

      begin
        config_path = File.expand_path(File.join(self.root, config_path)).to_s
        config = self.load_config_for_env(config_path, self.env)
      rescue
        raise ConfigLoadingError, "Failed to load required config for environment '#{self.env}': #{config_path}"
      end

      # Merge required + optional keys.
      keys_values = optional_keys.merge(required_keys)

      # Stash found keys from the config into ENV.
      keys_values.each do |extected_env_key, extected_yaml_key|
        ::Yaml2env::LOADED_ENV[extected_env_key.to_s] = ::ENV[extected_env_key.to_s] = config[extected_yaml_key.to_s]
        self.logger.info ":: ENV[#{extected_env_key.inspect}] = #{::ENV[extected_env_key.to_s].inspect}" if self.logger?
      end

      # Raise error if any credentials are missing.
      required_keys.keys.each do |env_key|
        ::Yaml2env::LOADED_ENV[env_key.to_s] ||
          raise(MissingConfigKeyError, "ENV variable '#{env_key}' needs to be set. Query: #{keys_values.inspect}. Found: #{config.inspect}")
      end
    end

    def load(config_path, required_keys = {}, optional_keys = {})
      begin
        self.load!(config_path, required_keys, optional_keys)
      rescue Error => e
        if self.logger?
          ::Yaml2env.logger.warn("[Yaml2env]: #{e} -- called from: #{__FILE__})")
        end
      end
      true
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
      self.env ||= if ::ENV.key?('RACK_ENV')
        ::ENV['RACK_ENV']
      elsif defined?(::Rails)
        ::Rails.env
      elsif defined?(::Sinatra::Application)
        ::Sinatra::Application.environment
      else
        raise DetectionFailedError, "Failed to auto-detect Yaml2env.root (config root). Specify environment before loading any configs/initializers using Yaml2env, e.g. Yaml2env.env = 'development'."
      end
    end

    def logger?
      self.logger.respond_to?(:info)
    end

    def root?
      !self.root.blank?
    end

    def env?(*args)
      if args.size > 0
        raise HumanError, "Seriously, what are you trying to do? *<:)" if args.size > 1 && args.count { |a| a.blank? } > 1
        args.any? do |arg|
          arg.is_a?(Regexp) ? self.env.to_s =~ arg : self.env.to_s == arg.to_s
        end
      else
        !self.env.blank?
      end
    end

    protected

      def load_config(config_file)
        YAML.load(File.open(config_file))
      end

      def load_config_for_env(config_file, env)
        config = self.load_config(config_file)
        config[env]
      end

  end

end
