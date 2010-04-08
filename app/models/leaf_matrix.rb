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
# Do not simply use empty_rows, as this will exclude rows containing masked cells.
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
#  def write_cells_inverted(open_file)
#    cells.each do |entry|
#      entry.write(open_file)
#    end
#
#    open_file
#  end

  # We want to invert the stuff we write as if this weren't a mask.
  swap_methods :write_cells, :write_cells_inverted, :write_cells_temporary
  swap_methods :write_rows, :write_rows_inverted, :write_rows_temporary


#  def write_rows_inverted(open_file)
#    rows.each do |row|
#      open_file.puts row
#    end
#  end

end