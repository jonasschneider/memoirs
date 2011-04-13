require "digest/md5"
require "sinatra"
require "haml"
require "sass"
require "mongoid"
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


use Rack::Session::Cookie, :expire_after => 34128000

before do
  content_type 'text/html', :charset => 'utf-8'
end

helpers MemoirHelpers

# GET /
# Index page.
get '/' do
  @skip = (params[:skip] && params[:skip].to_i) || 0
  @memoirs = Memoir.desc(:created_at).skip(@skip).limit(3).to_a
  haml :index
end


# GET /123
# Show page.
get %r{^/([0-9]+)$} do |number|
  @memoir = Memoir.find_by_number(number.to_i)
  haml :show
end


# GET /show/abc4fc45dea56f
# Legacy show.
get '/show/:id' do
  memoir = Memoir.find(params[:id])
  redirect url_for_memoir(memoir)
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
      Thread.new do
        post_memoir_to_facebook(@memoir)
      end
    end
    redirect '/'
  else
    render :new
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
    render :edit
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


# GET /feed.rss
# RSS feed.
get '/feed.rss' do
  @memoirs = Memoir.desc(:created_at).limit(15)
  content_type 'application/rss+xml', :charset => 'utf-8'
  builder :rss
end