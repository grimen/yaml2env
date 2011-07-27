# -*- encoding: utf-8 -*-
require 'rubygems'
require 'bundler'
Bundler.require

require 'minitest/autorun'
require 'minitest/unit'
require 'minitest/spec'
require 'minitest/pride'
require 'minitest/mock'

require 'yaml2env'

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
