require "sinatra"
require "haml"
require "sass"

set :haml, :format => :html5

helpers do
  def header(header)
    @header = header
  end
  
  def facebook_like_button
   '<iframe src="http://www.facebook.com/plugins/like.php?href='+Rack::Utils.escape(request.url)+'&amp;layout=button_count&amp;show_faces=false&amp;width=80&amp;action=like&amp;font=tahoma&amp;colorscheme=light&amp;height=21" scrolling="no" frameborder="0" style="border:none; width:80px; height:21px; overflow:hidden; allowTransparency="true" class="facebook-like-button"></iframe>'
  end
end

get '/' do
  content_type 'text/html', :charset => 'utf-8'
  haml :index
end

get '/memoir/:id' do
  content_type 'text/html', :charset => 'utf-8'
  haml :show
end

get '/style.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :style
end

run Sinatra::Application