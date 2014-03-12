#\ -s puma

require "rubygems"
require "bundler/setup"

$:.unshift '.'
require 'memoirs'

require "rack/ssl"
require "rack-canonical-host"

class Catcher
  def initialize(app); @app = app; end

  def call(env)
    begin
      @app.call(env)
    rescue Exception => e
      $stderr.puts "Caught exception: #{e.inspect}"
      $stderr.puts "Caught exception: #{e.backtrace.join("\n")}"
      [500, { "Content-Type" => "text/plain"}, ["Sorry, irgendwas ist kaputt gegangen."]]
    end
  end
end

HOST = "memoirs.jonasschneider.com"
use Catcher unless ENV["RAISE_EXCEPTIONS"]
use Rack::ShowExceptions if ENV["SHOW_EXCEPTIONS"]
use Rack::SSL, hsts: true, host: HOST unless ENV["LAX_TRANSPORT"]
use Rack::CanonicalHost, HOST unless ENV["LAX_TRANSPORT"]

run App
