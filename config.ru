#\ -s puma

require "rubygems"
require "bundler/setup"

$:.unshift '.'
require 'memoirs'

require "rack-ssl-enforcer"
require "rack-canonical-host"

use Rack::ShowExceptions if ENV["SHOW_EXCEPTIONS"]
use Rack::SslEnforcer, hsts: true unless ENV["ALLOW_NON_HTTPS"]
use Rack::CanonicalHost, 'memoirs.jonasschneider.com' unless ENV["NO_FORCE_HOST"]

run App
