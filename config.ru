#\ -s puma

require "rubygems"
require "bundler/setup"

$:.unshift '.'
require 'memoirs'

require "rack-ssl"
require "rack-canonical-host"

HOST = "memoirs.jonasschneider.com"
use Rack::ShowExceptions if ENV["SHOW_EXCEPTIONS"]
use Rack::SSL, host: HOST unless ENV["ALLOW_NON_HTTPS"]
use Rack::CanonicalHost, HOST unless ENV["NO_FORCE_HOST"]

run App
