require "rubygems"
require "bundler/setup"

require "digest/md5"
require "sinatra"
require "haml"
require "sass"
require "mongoid"
require 'active_support/core_ext/string/filters' # String#truncate

require 'rest-graph'
require "facebook"

Mongoid.database = Mongo::Connection.from_uri(ENV["MONGO"]).db("memoirs_#{ENV["RACK_ENV"]}")

class Memoir
  include Mongoid::Document
  
  field :text
  field :person
  field :created_at, :type => DateTime
  
  before_create :update_created_at
  
  def self.find_by_number(number)
    Memoir.asc(:created_at).skip(number-1).first
  end
  
  
  def update_created_at
    self.created_at = Time.now.utc
  end
  
  def number
    Memoir.where(:created_at.lt => created_at).count + 1
  end
  
  def previous
    Memoir.where(:created_at.lt => created_at).desc(:created_at).first
  end
  
  
  def next
    Memoir.where(:created_at.gt => created_at).asc(:created_at).first
  end
  
  
  def is_quote?
    text && !quoted_text.nil?
  end

  def quoted_text
    $1.gsub("\n", "<br />") if text.match(/^"(.*)"$/m)
  end
  
  def is_dialogue?
    text && !!text.match(/\[(.*)\]/)
  end
  
  def dialogue_lines
    lines = text.split("\n").map do |line|
      if line.match(/^\[(.*)\](\(.*\))?\s*(.*)$/) # dialogue line
        { :speaker => $1, :message => $3, :style => $2 }
      elsif line.match(/^\((.+)\)/) # action line
        { :action => line }
      else
        { :message => line }
      end
    end
  end
end

set :haml, :format => :html5

if ENV["RACK_ENV"] == "production"
  set :haml, :format => :html5, :ugly => true
end

use Rack::Session::Cookie, :expire_after => 34128000

before do
  content_type 'text/html', :charset => 'utf-8'
end

helpers do
  include Haml::Helpers
  
  def url_for_memoir(memoir)
    "http://#{request.host_with_port}/#{memoir.number}"
  end
  
  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Memoiren der Kursstufe")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    creds = ['jonas', 'jonas93']
    return true if session[:admin] == Digest::MD5.hexdigest(creds.to_s)
    
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    if @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == creds
      session[:admin] = Digest::MD5.hexdigest(creds.to_s)
    end
    false
  end
  
  def header(&block)
    @header = capture_haml(&block)
  end
  
  def cycle
    %w{a b}[@_cycle = ((@_cycle || -1) + 1) % 2]
  end
  
  def reset_cycle
    @_cycle = -1
  end
  
  def format_date(date)
    (date || Time.now).strftime("%d.%m.%y")
  end
  
  def facebook_like_button
   '<iframe src="http://www.facebook.com/plugins/like.php?href='+Rack::Utils.escape(request.url)+'&amp;layout=button_count&amp;show_faces=false&amp;width=80&amp;action=like&amp;font=tahoma&amp;colorscheme=light&amp;height=21" scrolling="no" frameborder="0" style="border:none; width:80px; height:21px; overflow:hidden; allowTransparency="true" class="facebook-like-button"></iframe>'
  end
  
  def faceboook_like_page_badge
    '<iframe src="http://www.facebook.com/plugins/likebox.php?href=https%3A%2F%2Fwww.facebook.com%2FMemoirenDerKursstufe&amp;width=350&amp;colorscheme=light&amp;show_faces=false&amp;stream=false&amp;header=false&amp;height=62" scrolling="no" frameborder="0" style="border:none; overflow:hidden; width:350px; height:62px;" allowTransparency="true"></iframe>'
  end
  
  def post_memoir_to_facebook(memoir)
    Thread.new do
      Facebook.post(:message => memoir.text.truncate(60), :link => url_for_memoir(memoir))
    end
  end
end

get '/' do
  @skip = (params[:skip] && params[:skip].to_i) || 0
  @memoirs = Memoir.desc(:created_at).skip(@skip).limit(3).to_a
  haml :index
end

get '/new' do
  protected!
  @memoir = Memoir.new
  haml :new
end

post '/' do
  protected!
  @memoir = Memoir.new(params[:memoir])
  if @memoir.save
    post_memoir_to_facebook(@memoir) if ENV["RACK_ENV"] == "production"
    redirect '/'
  else
    render :new
  end
end

get '/style.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :style
end

get %r{^/([0-9]+)$} do |number|
  @memoir = Memoir.find_by_number(number.to_i)
  haml :show
end

get '/show/:id' do
  memoir = Memoir.find(params[:id])
  redirect url_for_memoir(memoir)
end

post '/update/:id' do
  protected!
  @memoir = Memoir.find(params[:id])
  if @memoir.update_attributes(params[:memoir])
    redirect url_for_memoir(memoir)
  else
    render :edit
  end
end

get '/delete/:id' do
  protected!
  @memoir = Memoir.find(params[:id])
  @memoir.delete
  redirect "/"
end

get '/edit/:id' do
  protected!
  @memoir = Memoir.find(params[:id])
  haml :edit
end

get '/feed.rss' do
  @memoirs = Memoir.desc(:created_at).limit(15)
  content_type 'application/rss+xml', :charset => 'utf-8'
  builder :rss
end

get '/preview' do
  @memoir = Memoir.new(params[:memoir])
  haml :memoir, :locals =>  { :memoir => @memoir, :skip_details => true }, :layout => false
end

run Sinatra::Application