class Memoir
  include Mongoid::Document
  include Mongoid::FullTextSearch

  field :first_name
  field :last_name

  field :text
  field :person
  field :created_at, :type => DateTime
  
  fulltext_search_in :text, :person
  
  validates_presence_of :text, :person
  
  before_create :update_created_at

  before_save :maybe_escape

  def maybe_escape
    if ENV["SITE_NAME"]
      text.gsub!('<', '&lt;').gsub!('>', '&gt;')
    end
  end
  
  def self.find_by_number(number)
    Memoir.asc(:created_at).skip(number-1).first
  end
  
  
  def update_created_at
    self.created_at = Time.now.utc
  end
  
  def number
    Memoir.where(:created_at.lt => created_at).count + 1
  end
  
  def previous
    Memoir.where(:created_at.lt => created_at).desc(:created_at).first
  end
  
  
  def next
    Memoir.where(:created_at.gt => created_at).asc(:created_at).first
  end
  
  
  def is_quote?
    text && !quoted_text.nil?
  end

  def quoted_text
    $1.gsub("\n", "<br />") if text.match(/^"(.*)"$/m)
  end
  
  def is_dialogue?
    text && !!text.match(/\[(.*)\]/)
  end
  
  def dialogue_lines
    lines = text.split("\n").map do |line|
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