xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Memoiren der Kursstufe"
    xml.description "Memoiren der Kursstufe von Jonas Schneider."
    xml.link "http://memoirs.heroku.com"

    @memoirs.each do |memoir|
      xml.item do
        xml.title memoir.text
        xml.link "http://memoirs.heroku.com/show/#{memoir.id}"
        xml.description { xml.cdata!(memoir.text) }
        xml.pubDate memoir.created_at.utc
        xml.guid memoir.id
      end
    end
  end
end