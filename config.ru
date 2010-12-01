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
end


set :haml, :format => :html5

before do
  content_type 'text/html', :charset => 'utf-8'
end

helpers do
  def header(header)
    @header = header
  end
  
  def format_date(date)
    date.strftime("%d.%m.%y")
  end
  
  def facebook_like_button
   '<iframe src="http://www.facebook.com/plugins/like.php?href='+Rack::Utils.escape(request.url)+'&amp;layout=button_count&amp;show_faces=false&amp;width=80&amp;action=like&amp;font=tahoma&amp;colorscheme=light&amp;height=21" scrolling="no" frameborder="0" style="border:none; width:80px; height:21px; overflow:hidden; allowTransparency="true" class="facebook-like-button"></iframe>'
  end
end

get '/' do
  @memoirs = Memoir.all
  haml :index
end

get '/memoir/:id' do
  @memoir = Memoir.find(params[:id])
  haml :show
end

get '/style.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :style
end

run Sinatra::Application