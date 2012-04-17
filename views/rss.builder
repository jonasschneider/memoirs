xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title ENV['SITE_NAME'] || "Memoiren der Kursstufe"
    xml.description ENV['SITE_NAME'] || "Memoiren der Kursstufe von Jonas Schneider."
    unless ENV['SITE_NAME']
      xml.link "http://memoirs.heroku.com"
    end

    @memoirs.each do |memoir|
      xml.item do
        xml.title memoir.text
        xml.link url_for_memoir(memoir)
        xml.description { xml.cdata!(memoir.text) }
        xml.pubDate memoir.created_at.utc
        xml.guid memoir.id
      end
    end
  end
end