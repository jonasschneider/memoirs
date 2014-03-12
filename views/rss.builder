xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title @current_category.name
    xml.description @current_category.description || @current_category.name
    xml.link url_for('/')

    @memoirs.each do |memoir|
      xml.item do
        xml.title memoir.body.truncate(60)
        xml.link url_for_memoir(memoir)
        xml.description { xml.cdata!(memoir.body) }
        xml.pubDate memoir.created_at.utc
        xml.guid memoir.id
      end
    end
  end
end
