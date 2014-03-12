class CategoryApp < Sinatra::Base
  set :root, File.dirname(__FILE__)+"/.."
  helpers MemoirHelpers

  helpers do
    include Rack::Utils
  end

  configure do
    set :haml, :format => :html5
  end

  configure :production do
    set :haml, :format => :html5, :ugly => true
  end

  before do
    content_type 'text/html', :charset => 'utf-8'
  end

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
      redirect url_for('/')
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
    redirect url_for('/')
  end


  # GET /preview
  # Ajax-powered memoir preview.
  get '/preview' do
    @memoir = Memoir.new(params[:memoir])
    haml :memoir, :locals =>  { :memoir => @memoir, :skip_details => true }, :layout => false
  end

  # GET /feed.rss
  # RSS feed.
  get '/feed.rss' do
    @memoirs = Memoirs.first_n(15)
    content_type 'application/rss+xml', :charset => 'utf-8'
    builder :rss
  end
end