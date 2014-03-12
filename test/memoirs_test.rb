require './'+File.join(File.dirname(__FILE__), 'env')

class MemoirsTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    DB[:memoirs].delete
  end

  def app
    Sinatra::Application
  end

  def test_it_shows_memoir_list
    Memoirs.add(Memoir.new(:body => 'o lol', :editor => 'lol'))

    get '/'

    assert last_response.ok?
    assert_match /o lol/, last_response.body
  end

  def test_it_shows_single_memoir
    Memoir.create!(:body => 'o lol', :editor => 'lol')

    get '/1'

    assert last_response.ok?
    assert_match /o lol/, last_response.body
  end

  def test_it_deprecates_old_routes
    memoir = Memoir.create!(:body => "o lol", :editor => 'lol')

    get "/show/#{memoir.id}"

    assert last_response.redirect?
    assert_equal 'http://example.org/1', last_response.headers['Location']
  end

  def test_it_creates_memoirs
    basic_authorize 'jonas', 'jonas'

    post '/', :memoir => { :body => "sup guys", :editor => 'me' }
    follow_redirect!

    assert last_response.ok?
    assert_match /sup guys/, last_response.body
  end

  def test_it_updates_memoirs
    basic_authorize 'jonas', 'jonas'
    memoir = Memoir.create!(:body => 'o lol', :editor => 'lol')

    post "/update/#{memoir.id}", :memoir => { :body => "sup guys", :editor => 'me' }
    assert_equal 'http://example.org/1', last_response.headers['Location']
    follow_redirect!

    assert last_response.ok?
    memoir.reload
    assert_equal "sup guys", memoir.text
    assert_match /sup guys/, last_response.body
  end

  def test_it_deletes_memoirs
    basic_authorize 'jonas', 'jonas'
    memoir = Memoir.create!(:body => 'o lol', :editor => 'lol')

    get "/delete/#{memoir.id}"
    assert_equal 0, Memoir.count
  end

  def test_it_searches
    a = Memoir.create!(:body => 'ohaiSHOWSTOPPER', :editor => 'lol')
    b = Memoir.create!(:body => 'oomatch', :editor => 'lol')
    c = Memoir.create!(:body => 'oo', :editor => 'lolmatch')

    get "/search", :query => "match"
    assert last_response.body.include?('oomatch')
    assert last_response.body.include?('lolmatch')
    assert !last_response.body.include?('SHOWSTOPPER')
  end
end
