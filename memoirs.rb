require "digest/md5"
require "sinatra"
require "haml"
require "sass"
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

use Rack::Session::Cookie, :expire_after => 34128000

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

  def find_by_number(number)
    load_one dataset.order(:created_at).offset(number-1)
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
    dataset.insert(memoir.attributes.merge(created_at: Time.now.utc))
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


# GET /show/abc4fc45dea56f
# Legacy show.
get '/show/:id' do
  memoir = Memoir.find(params[:id])
  redirect url_for_memoir(memoir)
end

# GET /random
# Redirect to a random memoir.
get '/random' do
  memoir = Memoir.skip((rand*(Memoir.count)).to_i).first
  redirect url_for_memoir(memoir)
end


# GET /search
# Full-text search.
get '/search' do
  @memoirs = Memoir.fulltext_search(params[:query], { :return_scores => true }).select{|d|d[1] > 1}.sort_by{|d| d[1]}.map{|d|d[0]}.reverse
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
  if @memoir.save
    if production?
      #Thread.new do
      #  post_memoir_to_facebook(@memoir)
      #end
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
  @memoir = Memoir.find(params[:id])
  if @memoir.update_attributes(params[:memoir])
    redirect url_for_memoir(@memoir)
  else
    haml :edit
  end
end


# GET /delete/:id
# Memoir deletion.
get '/delete/:id' do
  protected!
  @memoir = Memoir.find(params[:id])
  @memoir.delete
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
  @memoirs = Memoir.desc(:created_at).limit(15)
  content_type 'application/rss+xml', :charset => 'utf-8'
  builder :rss
end
