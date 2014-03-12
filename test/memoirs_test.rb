require './'+File.join(File.dirname(__FILE__), 'env')

class MemoirsTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    DB[:memoirs].delete
    @repo = MemoirRepo.new(1)
  end

  def app
    App
  end

  def test_it_shows_memoir_list
    @repo.add(Memoir.new(:body => 'o lol', :editor => 'lol'))

    get '/memoiren-der-kursstufe'

    assert last_response.ok?
    assert_match /o lol/, last_response.body
  end

  def test_it_shows_single_memoir
    @repo.add(Memoir.new(:body => 'o lol', :editor => 'lol'))

    get '/memoiren-der-kursstufe/1'

    assert last_response.ok?
    assert_match /o lol/, last_response.body
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
    memoir_id = @repo.add(Memoir.new(:body => 'o lol', :editor => 'lol'))

    post "/update/#{memoir_id}", :memoir => { :body => "sup guys", :editor => 'me' }
    assert_equal 'http://example.org/1', last_response.headers['Location']
    follow_redirect!

    assert last_response.ok?
    memoir = @repo.find(memoir_id)
    assert_equal "sup guys", memoir.body
    assert_match /sup guys/, last_response.body
  end

  def test_it_deletes_memoirs
    basic_authorize 'jonas', 'jonas'
    memoir_id = @repo.add(Memoir.new(:body => 'o lol', :editor => 'lol'))

    get "/delete/#{memoir_id}"
    assert_equal 0, @repo.count
  end

  def test_it_searches
    a = @repo.add(Memoir.new(:body => 'ohaiSHOWSTOPPER', :editor => 'lol'))
    b = @repo.add(Memoir.new(:body => 'oomatch', :editor => 'lol'))
    c = @repo.add(Memoir.new(:body => 'xxmatchxx', :editor => 'ohai'))

    get "/search", :query => "match"
    assert last_response.body.include?('oomatch')
    assert last_response.body.include?('xxmatchxx')
    assert !last_response.body.include?('SHOWSTOPPER')
  end

  def test_rss
    get "/feed.rss"
  end

  def test_random
    @repo.add(Memoir.new(:body => 'o lol', :editor => 'lol'))
    get "/random"
  end
end
