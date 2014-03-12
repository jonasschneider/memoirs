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

Categories = {
  1 => 'memoiren-der-kursstufe',
  2 => 'memoiren-fuer-alle',
  3 => 'memoiren-des-auditoriums',
}

Memoirs = MemoirRepo.new

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

  Categories.each do |cat_id, cat_name|
    map "/#{cat_name}" do
      run CategoryApp.new
    end
  end

  run Assets
}
