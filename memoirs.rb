ENV["RACK_ENV"] = "production"
require "digest/md5"
require "sinatra/base"

Sinatra::Base.configure do |c|
  c.set :show_exceptions, false
  c.set :raise_errors, true
end

require "haml"
require "sass"
require 'redcarpet'
require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/string/filters' # String#truncate
require 'rest-graph'
require 'lib/facebook'
require 'lib/memoir'
require 'lib/memoir_helpers'

require 'lib/memoir_repo'
require 'lib/category_app'

require 'sequel'
DB = Sequel.connect(ENV["DATABASE_URL"])

Category = Struct.new(:mnemonic, :name, :by_me?, :the_original?, :description)
Categories = {
  1 => Category.new('memoiren-der-kursstufe', 'Memoiren der Kursstufe', true, true, "Memoiren der Kursstufe von Jonas Schneider."),
  2 => Category.new('memoiren-fuer-alle', 'Memoiren für alle!', false, false, nil),
  3 => Category.new('memoiren-des-auditoriums', 'Memoiren des Auditoriums', true, false, nil),
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

class Frontpage
  def initialize(app, options)
    @nonfrontpage_app = app
    @frontpage_app = options[:frontpage_app]
  end

  def call(env)
    if env["PATH_INFO"] == "/"
      @frontpage_app.call(env)
    else
      @nonfrontpage_app.call(env)
    end
  end
end

App = Rack::Builder.new {
  use Rack::Session::Cookie, secret: ENV["SESSION_SECRET"]

  use Assets

  Categories.each do |cat_id, cat|
    map "/#{cat.mnemonic}" do
      run CategoryApp.new(cat_id)
    end
  end

  use Frontpage, frontpage_app: CategoryApp.new(3)

  # legacy category
  run CategoryApp.new(1)
}
