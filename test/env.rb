require "rubygems"
require "bundler/setup"

require 'test/unit'
require 'rack/test'
require 'memoirs'

configure do
  set :show_exceptions, false
  set :raise_errors, true
end

ENV['RACK_ENV'] = 'test'

Mongoid.database = Mongo::Connection.from_uri('mongodb://jonas:jonas@flame.mongohq.com:27093/memoirs_test').db('memoirs_test')