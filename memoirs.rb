require "digest/md5"
require "sinatra/base"
require "rack-ssl-enforcer"
require "haml"
require "sass"
require 'redcarpet'
require "mongoid"
require "mongoid_fulltext"
require 'active_support/core_ext/string/filters' # String#truncate
require 'rest-graph'
require 'lib/facebook'
require 'lib/memoir'
require 'lib/memoir_helpers'

require 'lib/memoir_repo'
require 'lib/category_app'

require 'sequel'
DB = Sequel.connect(ENV["DATABASE_URL"])

Category = Struct.new(:mnemonic, :name, :by_me?, :the_original?)
Categories = {
  1 => Category.new('memoiren-der-kursstufe', 'Memoiren der Kursstufe', true, true),
  2 => Category.new('memoiren-fuer-alle', 'Memoiren für alle!', false, false),
  3 => Category.new('memoiren-des-auditoriums', 'Memoiren des Auditoriums', true, false),
}

class Assets < Sinatra::Base
  # GET /style.css
  # Stylesheet.
  get '/style.css' do
    content_type 'text/css', :charset => 'utf-8'
    sass :style
  end

  # GET /mobile.css
  # Mobile Stylesheet.
  get '/mobile.css' do
    content_type 'text/css', :charset => 'utf-8'
    sass :mobile
  end
end

App = Rack::Builder.new {
  use Rack::SslEnforcer, hsts: true unless ENV["ALLOW_NON_HTTPS"]
  use Rack::Session::Cookie, secret: ENV["SESSION_SECRET"]
  use Assets

  Categories.each do |cat_id, cat|
    map "/#{cat.mnemonic}" do
      run CategoryApp.new(cat_id)
    end
  end

  # legacy category
  run CategoryApp.new(1)
}
