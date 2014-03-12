ENV['DATABASE_URL'] ||= "postgres://jonas@localhost/memoirs_test"
ENV['LAX_TRANSPORT'] = "true"
ENV['SESSION_SECRET'] = 'totally sekrit'

require "rubygems"
require "bundler/setup"

$:.unshift File.join(File.dirname(__FILE__), '..')

require 'test/unit'
require 'rack/test'

require 'memoirs'
