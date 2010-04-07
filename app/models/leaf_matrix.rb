# LeafMatrix is a child type of TreeMatrix. It must have a parent, and it masks
# a NodeMatrix.
#
# Even though LeafMatrix is a mask, it computes set differences for methods like
# cells in order to make it appear that it is not. In order to get the actual
# cells, you need to call the this_cells method.
#
# Similarly, write_cells will print based on cells, not this_cells. If you want
# to print a test set, though, you would need to use write_cells_inverted, which
# would print the actual cells associated with this matrix as the database sees
# them.
#
# A row test set will consist not only of masked cells but also some masked rows.
# These are stored as empty_rows; thus, the training set would be the parent
# NodeMatrix's empty_rows minus this_empty_rows for the LeafMatrix.
class LeafMatrix < TreeMatrix
  acts_as_tree_leaf :node_class_name => 'NodeMatrix'
  mask_leaf_parent :cells, :empty_rows

  def cells_for_display(res = {})
    cells.each do |entry|
      res[entry.to_s(":")] = CellValue.new
    end
    this_cells.each do |entry|
      res[entry.to_s(":")] = CellValue.new(true) # masked
    end
    res
  end

protected

  # write_contents writes the whole matrix, not a mask of it.
  #
  # This function writes just the mask.
  def write_cells_inverted(open_file)
    cells.each do |entry|
      entry.write(open_file)
    end

    open_file
  end

  def write_rows_inverted(open_file)
    
  end

end