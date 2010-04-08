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

  # write_cells writes the whole matrix, not a mask of it.
  #
  # This function writes a mask.
  def write_cells_inverted(open_file)
    (parent.cells.active_record_difference(cells)).each do |entry|
      # Construct a new cell temporarily (don't save it), and use its write
      # function to do the output.
      entry.write(open_file)
    end

    open_file
  end


  # write_rows writes the whole matrix, not a mask of it.
  #
  # This function writes a mask (only the rows not included in this Matrix).
  def write_rows_inverted(open_file)
    (parent.rows - rows).each do |entry|
      open_file.puts entry
    end

    open_file
  end

  def child_filename_internal file_prefix, child_matrix
    "#{file_prefix}.#{children.count.to_s}-#{child_matrix.cardinality}"
  end
end

# Divide some set into num_pieces equal or one-off portions
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