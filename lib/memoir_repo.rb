class MemoirRepo
  def initialize(category_id)
    @category_id = category_id
    @dataset = DB[:memoirs].where('category_id = ?', @category_id).reverse_order(:created_at)
  end

  def list(offset)
    load dataset.offset(offset).limit(3)
  end

  def count
    dataset.count
  end

  def first_n(n)
    load dataset.limit(n)
  end

  def find(id)
    load_one dataset.filter('id = ?', id)
  end

  def find_by_number(number)
    load_one dataset.order(:created_at).offset(number-1)
  end

  def number(memoir)
    count_older_than(memoir.created_at) + 1
  end

  def previous(to_memoir)
    first_older_than(to_memoir.created_at)
  end

  def next(to_memoir)
    first_newer_than(to_memoir.created_at)
  end

  def sample
    load_one dataset.where('embargoed_until IS NULL or embargoed_until < now()').offset((Kernel.rand*(dataset.count)).to_i)
  end

  def add(memoir)
    return false unless memoir.valid?
    dataset.insert(memoir.attributes.merge(created_at: Time.now.utc, category_id: @category_id))
  end

  def update(memoir)
    return false unless memoir.id && memoir.valid?
    dataset.filter('id = ?', memoir.id).update(memoir.attributes)
  end

  def fulltext_search(query_string)
    like = "%#{query_string.downcase}%"
    load dataset.filter('lower(body) like ? or lower(subtext)', like)
  end

  protected

  def count_older_than(time)
    dataset.filter("created_at < ?", time).count
  end

  def first_older_than(time)
    load_one dataset.filter("created_at < ?", time)
  end

  def first_newer_than(time)
    load_one dataset.filter("created_at > ?", time).order(:created_at)
  end

  def load(records)
    records.map{ |record| r_to_o(record) }
  end

  def load_one(dataset)
    dataset.limit(1).map{ |record| r_to_o(record) }.first
  end

  def r_to_o(record)
    Memoir.new(record.slice(:id, :body, :editor, :created_at, :subtext, :embargoed_until))
  end

  def dataset
    @dataset
  end
end
