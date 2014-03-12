class Memoir
  attr_accessor :id, :body, :editor, :created_at, :category_id

  def initialize(initial_attributes = {})
    update_attributes(initial_attributes)
  end

  def attributes
    { body: body, editor: editor, category_id: category_id }
  end

  def update_attributes(new_attributes)
    new_attributes.each do |k,v|
      self.send("#{k}=".to_sym, v)
    end
  end

  def valid?
    attributes.all?{|k,v| !v.nil? }
  end

  def maybe_escape
    if ENV["SITE_NAME"]
      self.text = (text || '').gsub('<', '&lt;').gsub('>', '&gt;')
    end
    true
  end

  def number
    Memoirs.count_older_than(created_at) + 1
  end

  def previous
    Memoirs.first_older_than(created_at)
  end

  def next
    Memoirs.first_newer_than(created_at)
  end

  QUOTE_EX = /^"(.*)"(?: - (.*))?$/m

  def is_quote?
    body && body.match(QUOTE_EX)
  end

  def quoted_text
    $1.gsub("\n", "<br />") if body.match(QUOTE_EX)
  end

  def quote_source
    $2 if body.match(QUOTE_EX)
  end

  def is_dialogue?
    body && !!body.match(/\[(.*)\]/)
  end

  def dialogue_lines
    lines = body.split("\n").map do |line|
      if line.match(/^\[(.*)\](\(.*\))?\s*(.*)$/) # dialogue line
        { :speaker => $1, :message => $3, :style => $2 }
      elsif line.match(/^\((.+)\)/) # action line
        { :action => line }
      else
        { :message => line }
      end
    end
  end
end
