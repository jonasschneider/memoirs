#http://napkin.highgroove.com/articles/2009/07/19/how-to-update-a-facebook-page-status-using-the-facebook-api
require 'rest-graph'


module Facebook
  #APP_APIKEY = "720e8dd63e2ea421aa8c26f39428815c"
  #APP_SECRET = "49dbe7c18d0be30e900fc52e145f860e"
  
  APP_TOKEN = "116363685054223|66e638ac1fd4dd03e04dddc9-1557295535|165459146823786|Yg7ZUzwAUwg2EaHc7mVkVzTDfWE" # page token

  # TO GET TOKEN
  #fb_session = Facebooker::Session.create(APP_APIKEY, APP_SECRET)
  #fb_session.auth_token = APP_TOKEN
  #x= p fb_session.post("facebook.auth.getSession", :auth_token => "A5CLIH").inspect
  #p x.inspect

  def self.post(options)
    # :message => The status message
    # :link => A Link
    
    rg = ::RestGraph.new(:access_token => APP_TOKEN)
    rg.post("me/feed", options)
  end
end