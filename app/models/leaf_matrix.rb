# LeafMatrix is a child type of TreeMatrix. It must have a parent, and it masks
# a NodeMatrix.
class LeafMatrix < TreeMatrix
  acts_as_tree_leaf :node_class_name => 'NodeMatrix'
  mask_leaf_parent :cells
  delegate_to_parent :row_count

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
    this_cells.each do |entry|
      entry.write(open_file)
    end

    open_file
  end

  def write_rows_inverted(open_file)
    
  end

end