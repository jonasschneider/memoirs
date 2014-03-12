#\ -s puma

require "rubygems"
require "bundler/setup"

$:.unshift '.'
require 'memoirs'

require "rack/ssl"
require "rack-canonical-host"

HOST = "memoirs.jonasschneider.com"
use Rack::ShowExceptions if ENV["SHOW_EXCEPTIONS"]
use Rack::SSL, hsts: true, host: HOST unless ENV["LAX_TRANSPORT"]
use Rack::CanonicalHost, HOST unless ENV["LAX_TRANSPORT"]

run App
