class MemoirRepo
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

  def sample
    load_one dataset.offset((Kernel.rand*(dataset.count)).to_i)
  end

  def count_older_than(time)
    dataset.filter("created_at < ?", time).count
  end

  def first_older_than(time)
    load_one dataset.filter("created_at < ?", time)
  end

  def first_newer_than(time)
    load_one dataset.filter("created_at > ?", time)
  end

  def add(memoir)
    return false unless memoir.valid?
    dataset.insert(memoir.attributes.merge(created_at: Time.now.utc))
  end

  def update(memoir)
    return false unless memoir.id && memoir.valid?
    dataset.filter('id = ?', memoir.id).update(memoir.attributes)
  end

  def delete(id)
    dataset.filter('id = ?', id).delete
  end

  def fulltext_search(query_string)
    like = "%#{query_string}%"
    load dataset.filter('body like ?', like)
  end

  protected

  def load(records)
    records.map{ |record| Memoir.new(record) }
  end

  def load_one(dataset)
    dataset.limit(1).map{ |record| Memoir.new(record) }.first
  end

  def dataset
    DB[:memoirs].reverse_order(:created_at)
  end
end
