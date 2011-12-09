# -*- encoding: utf-8 -*-
require 'minitest/autorun'
require 'minitest/unit'
require 'minitest/spec'
require 'minitest/pride'
require 'minitest/mock'

require 'yaml2env'

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
        module ::Rails
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
      module ::Sinatra
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

def silence_all_warnings
  # Ruby 1.8: Kernel.silence_warnings { yield }
  old_verbose = $VERBOSE
  $VERBOSE = nil
  yield
  $VERBOSE = old_verbose
end

def with_constants(constants, &block)
  saved_constants = {}
  constants.each do |constant, value|
    saved_constants[constant] = Object.const_get(constant)
    silence_all_warnings do
      Object.const_set(constant, value)
    end
  end

  begin
    block.call
  ensure
    constants.each do |constant, value|
      silence_all_warnings do
        Object.const_set(constant, saved_constants[constant])
      end
    end
  end
end

def with_values(object, new_values)
  old_values = {}
  new_values.each do |key, value|
    old_values[key] = object.send key
    object.send :"#{key}=", value
  end
  yield
ensure
  old_values.each do |key, value|
    object.send :"#{key}=", value
  end
end