# This Matrix subclass is used for creating a hierachy of matrices, where some
# mask others.
#
# NodeMatrix and LeafMatrix inherit from TreeMatrix. NodeMatrix is for root and
# branch nodes (that aren't leaves). LeafMatrix is for leaf nodes, which are
# designed to more efficiently store cross-validation information as masks.
class TreeMatrix < Matrix

  # Get a hash of statistics on this matrix.
  def statistics
    h = super
    h["cells"] = cells.count
    h["entries"] = entries.count
    h["empty_rows"] = empty_rows.count
    h
  end

protected

  # Make a copy of an entry for this matrix. If this matrix is a leaf, this
  # entry will be treated as a mask.
  #
  # This function is internal-only.
  def clone_entry entry
    raise(ArgumentError, "Need Cell or EmptyRow") unless entry.is_a?(Entry)
    entry.class.send :create!, {:matrix_id => id, :i => entry.i, :j => entry.j}
  end

  # Returns the default options for write() and the functions it calls.
  def write_options options = {}
    super.merge({
      :invert_mask => false
    }).merge options
  end

  # Write the contents of the matrix, keeping in mind that it may be a mask or
  # the full matrix. This should really never be called externally.
  # MAY NEED REWRITE.
  def write_cells(open_file, options)
    if options[:invert_mask]
      write_contents_inverted(open_file)      # Complex case.
    else
      super(open_file)  # Simple case.
    end

    open_file
  end

  def child_filename_internal file_prefix, child_matrix
    "#{file_prefix}.#{children.count.to_s}-#{child_matrix.cardinality}"
  end

  # Set an in-memory property for matrices that have been built but not saved.
  # This keeps us from having to query the database during recursion on unsaved
  # objects.
  def built_rows= r
    @built_rows = r
  end

  # Returns saved rows if the property is not set.
  def built_rows
    if defined?(@built_rows)
      @built_rows
    else
      row_indeces
    end
  end
end

def split_set item_set, num_pieces
  raise(ArgumentError, "item_set is empty") if item_set.size == 0
  num_per_piece  = Array.new(num_pieces)
  results        = Array.new(num_pieces)
  startpos       = 0

  # Figure out the sizes of the splits
  (0...num_pieces).each do |piece|
    num_per_piece[piece]  =  item_set.size / num_pieces
    # Uneven division: need to increase the first set's size.
    num_per_piece[piece] += 1 if piece < item_set.size % num_pieces

    results[piece]        = item_set.slice(startpos, num_per_piece[piece])
    startpos             += num_per_piece[piece]
  end

  results
end

def combine_all_but_one item_sets, leave_out
  item_set = []
  (0...item_sets.size).each do |n|
    next if n == leave_out
    item_set.concat item_sets[n]
  end

  item_set
end