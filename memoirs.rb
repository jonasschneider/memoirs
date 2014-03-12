require "digest/md5"
require "sinatra"
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

configure do
  set :haml, :format => :html5
end

configure :production do
  set :haml, :format => :html5, :ugly => true
end

require 'sequel'
DB = Sequel.connect(ENV["DATABASE_URL"])

use Rack::Session::Cookie, secret: "ohai"#ENV["SESSION_SECRET"]

before do
  content_type 'text/html', :charset => 'utf-8'
end

helpers MemoirHelpers

helpers do
  include Rack::Utils
end

class MemoirRepo
  def list(offset)
    load dataset.offset(offset).limit(3)
  end

  def count
    dataset.count
  end

  def first_n(n)
    load dataset.limit(n)
  end

  def find(id)
    load_one dataset.filter('id = ?', id)
  end

  def find_by_number(number)
    load_one dataset.order(:created_at).offset(number-1)
  end

  def sample
    load_one dataset.offset((Kernel.rand*(dataset.count)).to_i)
  end

  def count_older_than(time)
    dataset.filter("created_at < ?", time).count
  end

  def first_older_than(time)
    load_one dataset.filter("created_at < ?", time)
  end

  def first_newer_than(time)
    load_one dataset.filter("created_at > ?", time)
  end

  def add(memoir)
    return false unless memoir.valid?
    dataset.insert(memoir.attributes.merge(created_at: Time.now.utc))
  end

  def update(memoir)
    return false unless memoir.id && memoir.valid?
    dataset.filter('id = ?', memoir.id).update(memoir.attributes)
  end

  def delete(id)
    dataset.filter('id = ?', id).delete
  end

  def fulltext_search(query_string)
    like = "%#{query_string}%"
    load dataset.filter('body like ?', like)
  end

  protected

  def load(records)
    records.map{ |record| Memoir.new(record) }
  end

  def load_one(dataset)
    dataset.limit(1).map{ |record| Memoir.new(record) }.first
  end

  def dataset
    DB[:memoirs].reverse_order(:created_at)
  end
end

Memoirs = MemoirRepo.new

# GET /
# Index page.
get '/' do
  @skip = (params[:skip] && params[:skip].to_i) || 0
  @memoirs = Memoirs.list(@skip)
  haml :index
end


# GET /123
# Show page.
get %r{^/([0-9]+)$} do |number|
  @memoir = Memoirs.find_by_number(number.to_i)
  haml :show
end

# GET /random
# Redirect to a random memoir.
get '/random' do
  memoir = Memoirs.sample
  redirect url_for_memoir(memoir)
end


# GET /search
# Full-text search.
get '/search' do
  @memoirs = Memoirs.fulltext_search(params[:query])
  @skip = (params[:skip] && params[:skip].to_i) || 0
  haml :index
end


# GET /new
# New memoir form.
get '/new' do
  protected!
  @memoir = Memoir.new
  haml :new
end

# POST /
# Memoir creation.
post '/' do
  protected!
  @memoir = Memoir.new(params[:memoir])
  if Memoirs.add(@memoir)
    if ENV["POST_TO_FACEBOOK"]
      Thread.new do
        post_memoir_to_facebook(@memoir)
      end
    end
    redirect '/'
  else
    haml :new
  end
end


# GET /edit/abc4fc45dea56f
# Edit form.
get '/edit/:id' do
  protected!
  @memoir = Memoir.find(params[:id])
  haml :edit
end


# POST /update/:id
# Memoir update.
post '/update/:id' do
  protected!
  @memoir = Memoirs.find(params[:id])
  @memoir.update_attributes(body: params[:memoir]["body"], editor: params[:memoir]["editor"])
  if Memoirs.update(@memoir)
    redirect url_for_memoir(@memoir)
  else
    haml :edit
  end
end


# GET /delete/:id
# Memoir deletion.
get '/delete/:id' do
  protected!
  Memoirs.delete(params[:id])
  redirect "/"
end


# GET /preview
# Ajax-powered memoir preview.
get '/preview' do
  @memoir = Memoir.new(params[:memoir])
  haml :memoir, :locals =>  { :memoir => @memoir, :skip_details => true }, :layout => false
end


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

# GET /feed.rss
# RSS feed.
get '/feed.rss' do
  @memoirs = Memoirs.first_n(15)
  content_type 'application/rss+xml', :charset => 'utf-8'
  builder :rss
end
