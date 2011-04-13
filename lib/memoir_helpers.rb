module MemoirHelpers
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