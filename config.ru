require "rubygems"
require "bundler/setup"

require "sinatra"
require "haml"
require "sass"
require "mongoid"

Mongoid.database = Mongo::Connection.from_uri(ENV["MONGO"]).db("memoirs_#{ENV["RACK_ENV"]}")

class Memoir
  include Mongoid::Document
  
  field :text
  field :person
  field :created_at, :type => DateTime
  
  before_create :update_created_at
  
  def update_created_at
    self.created_at = Time.now.utc
  end
  
  def number
    Memoir.where(:created_at.lt => created_at).count + 1
  end
  
  
  def is_quote?
    !quoted_text.nil?
  end

  def quoted_text
    $1 if text.match(/^"(.*)"$/)
  end
  
  def is_dialogue?
    !!text.match(/\[(.*)\]/)
  end
  
  def dialogue_lines
    lines = text.split("\n").map do |line|
      if line.match(/^\[(.*)\]\s*(.*)$/) # dialogue line
        { :speaker => $1, :message => $2 }
      else
        { :message => line }
      end
    end
  end
end


set :haml, :format => :html5

before do
  content_type 'text/html', :charset => 'utf-8'
end

helpers do
  
  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Memoiren der Kursstufe")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['jonas', 'jonas93']
  end
  
  def header(header)
    @header = header
  end
  
  def cycle
    %w{a b}[@_cycle = ((@_cycle || -1) + 1) % 2]
  end
  
  def reset_cycle
    @_cycle = -1
  end
  
  def format_date(date)
    date.strftime("%d.%m.%y")
  end
  
  def facebook_like_button
   '<iframe src="http://www.facebook.com/plugins/like.php?href='+Rack::Utils.escape(request.url)+'&amp;layout=button_count&amp;show_faces=false&amp;width=80&amp;action=like&amp;font=tahoma&amp;colorscheme=light&amp;height=21" scrolling="no" frameborder="0" style="border:none; width:80px; height:21px; overflow:hidden; allowTransparency="true" class="facebook-like-button"></iframe>'
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
    redirect '/'
  else
    render :new
  end
end

get '/style.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :style
end

get '/show/:id' do
  @memoir = Memoir.find(params[:id])
  haml :show
end

post '/update/:id' do
  protected!
  @memoir = Memoir.find(params[:id])
  if @memoir.update_attributes(params[:memoir])
    redirect "/show/#{@memoir.id}"
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

run Sinatra::Application