class Memoir
  attr_accessor :id, :body, :editor, :subtext, :created_at, :embargoed_until

  def initialize(initial_attributes = {})
    self.body = ""
    self.editor = ""
    update_attributes(initial_attributes)
  end

  def embargoed_until=(newdate)
    if newdate.nil? || (String === newdate && newdate.empty?)
      newdate = nil
    elsif !(Date === newdate)
      newdate = Date.parse(newdate)
    end
    @embargoed_until = newdate
  end

  def attributes
    { body: body, editor: editor, subtext: subtext, embargoed_until: embargoed_until }
  end

  def update_attributes(new_attributes)
    new_attributes.each do |k,v|
      self.send("#{k}=".to_sym, v)
    end
  end

  def valid?
    !body.nil? && !editor.nil?
  end

  QUOTE_EX = /^"(.*)"(?: - (.*))?$/m

  def is_quote?
    return true if defacto_quote?
    body.match(QUOTE_EX)
  end

  def quoted_text
    return defacto_quote_text if defacto_quote?
    $1.gsub("\n", "<br />") if body.match(QUOTE_EX)
  end

  def quote_source
    return defacto_quote_source if defacto_quote?
    $2 if body.match(QUOTE_EX)
  end

  def is_dialogue?
    body && !!body.match(/\[(.*)\]/)
  end

  def defacto_quote?
    dialogue_lines.length == 1 && dialogue_lines.first[:speaker] && !dialogue_lines.first[:style]
  end

  def defacto_quote_text
    dialogue_lines.first[:message]
  end

  def defacto_quote_source
    dialogue_lines.first[:speaker]
  end

  def dialogue_lines
    body.split("\n").map do |line|
      if line.match(/^\[(.*)\](\(.*\))?\s*(.*)$/) # dialogue line
        { :speaker => $1, :message => $3, :style => $2 }
      elsif line.match(/^\((.+)\)/) # action line
        { :action => line }
      else
        { :message => line }
      end
    end
  end

  def embargoed?
    !embargoed_until.nil? && Date.today < embargoed_until
  end
end
