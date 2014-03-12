ENV['RACK_ENV'] ||= 'test'
ENV['DATABASE_URL'] ||= "postgres://jonas@localhost/memoirs_test"
ENV['ALLOW_NON_HTTPS'] = "true"
ENV['SESSION_SECRET'] = 'totally sekrit'

require "rubygems"
require "bundler/setup"

$:.unshift File.join(File.dirname(__FILE__), '..')

require 'test/unit'
require 'rack/test'

require 'sinatra/base'
Sinatra::Base.configure do |c|
  c.set :show_exceptions, false
  c.set :raise_errors, true
end

require 'memoirs'
