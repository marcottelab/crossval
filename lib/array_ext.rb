class Array

  # Gives the array mean as a float. Can specify a different converter instead,
  # e.g., median(:to_i) for truncation.
  def mean(sym = :to_f)
    (size > 0) ? sum.to_f / size.send(sym) : 0.send(sym)
  end

  # Gives the array median as a float. Can specify a different converter instead,
  # e.g., median(:to_i) for truncation.
  def median(sym = :to_f)
    return nil if size == 0

    tmp = self.dup.sort
    middle  = (tmp.size - 1) / 2
    middle2 = tmp.size / 2

    if tmp.size % 2 == 0
      (tmp[middle] + tmp[middle2]) / 2.send(sym)
    else
      tmp[middle].send(sym)
    end
  end

  # Don't consider certain ActiveRecord information when calculating uniq using
  # this function.
  def active_record_uniq(exclude = [:id,:created_at,:updated_at])
    active_record_hash(exclude).values
  end

  # Set union for ActiveRecord -- considers all objects without their IDs,
  # timestamps, etc.
  def active_record_union(other_array, exclude = [:id,:created_at,:updated_at])
    h = active_record_hash(exclude)
    other_array.active_record_hash(exclude, h).values
  end

  # Set difference for ActiveRecord -- considers all objects without their IDs,
  # timestamps, etc.
  def active_record_difference(subtract, exclude = [:id, :created_at, :updated_at])
    h1 = active_record_hash(exclude)
    h2 = subtract.active_record_hash(exclude)
    d = []
    (h1.keys - h2.keys).each do |key|
      d << h1[key] if h1.has_key?(key)
    end
    d
  end

protected
  # Returns a hash of ActiveRecord objects with certain attributes excluded (e.g.,
  # id, created_at, updated_at
  def active_record_hash(exclude, h = {})
    each do |item|
      item_key    = clean_attributes(item, exclude).to_s
      h[item_key] = item unless h.has_key?(item_key)
    end
    h
  end
end

# Return an attributes hash for an ActiveRecord object with certain items removed.
def clean_attributes(obj, exclude = [:id,:created_at,:updated_at])
  attr = obj.attributes
  exclude.each do |k|
    attr.delete k.to_s
  end
  attr
end