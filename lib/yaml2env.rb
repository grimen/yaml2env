require 'yaml'
require 'logger'

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

    def load(config_path, required_keys = {}, optional_keys = {})
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

    def detect_root!
      self.root ||= if ::ENV.key?('RACK_ROOT')
        ::ENV['RACK_ROOT']
      elsif defined?(::Rails)
        ::Rails.root
      elsif defined?(::Sinatra::Application)
        ::Sinatra::Application.root
      else
        raise DetectionFailedError, "Failed to auto-detect Yaml.env (config environment). Specify environment before loading any configs/initializers using Yaml2env, e.g Yaml2env.env = 'development'."
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
        raise DetectionFailedError, "Failed to auto-detect Yaml2env.root (config root). Specify environment before loading any configs/initializers using Yaml2env, e.g Yaml2env.env = 'development'."
      end
    end

    def logger?
      self.logger.respond_to?(:info)
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
