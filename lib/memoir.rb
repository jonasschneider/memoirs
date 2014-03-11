class Memoir
  attr_accessor :id, :body, :editor, :created_at
  def initialize(attributes)
    attributes.each do |k,v|

      self.send("#{k}=".to_sym, v)
    end
  end

  # include Mongoid::Document
  # include Mongoid::FullTextSearch

  # field :first_name
  # field :last_name

  # field :text
  # field :person
  # field :created_at, :type => DateTime

  # fulltext_search_in :text, :person

  # validates_presence_of :text

  # before_create :update_created_at

  # before_save :maybe_escape

  def maybe_escape
    if ENV["SITE_NAME"]
      self.text = (text || '').gsub('<', '&lt;').gsub('>', '&gt;')
    end
    true
  end

  def self.find_by_number(number)
    Memoir.asc(:created_at).skip(number-1).first
  end


  def update_created_at
    self.created_at = Time.now.utc
  end

  def number
    Memoirs.filter("created_at < ?", created_at).count + 1
  end

  def previous
    Memoir.where(:created_at.lt => created_at).desc(:created_at).first
  end


  def next
    Memoir.where(:created_at.gt => created_at).asc(:created_at).first
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
