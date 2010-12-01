require "sinatra"
require "haml"
require "sass"

set :haml, :format => :html5

get '/' do
  content_type 'text/html', :charset => 'utf-8'
  haml :index
end

get '/style.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :style
end

run Sinatra::Application