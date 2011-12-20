ENV['RACK_ENV'] = 'test'

require "rubygems"
require "bundler/setup"

$:.unshift File.join(File.dirname(__FILE__), '..')

require 'test/unit'
require 'rack/test'
require 'memoirs'

configure do
  set :show_exceptions, false
  set :raise_errors, true
end