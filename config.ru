require "rubygems"
require "bundler/setup"

$:.unshift '.'
require 'memoirs'

Mongoid.database = Mongo::Connection.from_uri(ENV["MONGO"]).db("memoirs_#{ENV["RACK_ENV"]}")

run Sinatra::Application