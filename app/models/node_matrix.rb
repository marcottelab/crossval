# NodeMatrix is an abstraction of TreeMatrix. This type is used for a node that
# is not a leaf.
class NodeMatrix < TreeMatrix
  acts_as_tree_node :node_class_name => 'NodeMatrix', :leaf_class_name => 'LeafMatrix'
  # These things should be fetched from the parent if a parent is set.
  union_with_parent :empty_rows
  
  # This function will return true only if we have two-stage cross-validation
  # set up for a matrix.
  #
  # It will be used when creating Experiments -- so we know when to clone them
  # and put one on each child matrix instead of just the root.
  #
  # A fundamental assumption is that the tree is balanced (that if one child has
  # 5 children, all children have 5 children). If you created the tree by hand,
  # don't expect this to work.
  def has_grandchildren?
    return false if children.size == 0
    return false if children.first.children.size == 0
    true
  end

  # Gives a metric describing the number of cells in the matrix as a fraction of
  # the size -- in terms of the number of cells per column.
  def density
    target = self
    cc = target.column_count

    while cc == 0
      target = target.parent
      cc = target.column_count
    end

    (self.cells.count / cc.to_f).round
  end


protected

  # write_contents writes the whole matrix, not a mask of it.
  #
  # This function writes a mask.
  def write_cells_inverted(open_file)
    parent_cells = Matrix.find(self.parent_id).cells

    (parent_cells.collect{ |c| [c.i,c.j]} - cells.collect{ |c| [c.i,c.j]}).each do |entry|
      # Construct a new cell temporarily (don't save it), and use its write
      # function to do the output.
      Cell.new(:i => entry[0], :j => entry[1]).write(open_file)
    end

    open_file
  end

  # Force children to be written as testsets (rather than in the format dictated
  # by storage, which may be a training or a testset).
  def write_children_as_testsets file_prefix
    if children.first.mask?
      write_children file_prefix, {:force_not_masked => true}
    else
      write_children file_prefix, {:force_masked => true}
    end
  end
  
  def write_children file_prefix, options = {}
    unless children.first.nil?

      Dir.chdir(self.root) do
        # Write masked children one way and unmasked another, unless specified in
        # arguments to this function. # HERE
        unless options[:force_not_masked] || options[:force_masked]
          if children.first.mask?
            STDERR.puts("force not masked")
            options[:force_not_masked] = true
          else
            STDERR.puts("force masked")
            options[:force_masked] = true
          end
        end

        children.each do |child|
          child.write( child_filename_internal(file_prefix, child), options)
        end

      end
    end
  end

  # Get the set of cells or rows to fractalize. Called only by mask_fractalize_internal
  # and fractalize_internal.
  def set_to_fractalize meth, shuffle
    if self.built_rows.size == 0
      if new_record?
        raise StandardError, "Looks like an object was built but not saved and therefore its children are hidden."
      else
        raise StandardError, "Looks like you saved an empty object and want to fractalize it, but that seems silly."
      end
    end

    my_set = nil
    if meth == :cell
      my_set = self.cells.dup
      my_set.shuffle! if shuffle
    elsif meth == :row
      my_set = self.built_rows.dup # THIS IS PROBLEMATIC.
      raise(StandardError, "dup didn't work") if my_set.size == 0
      my_set.shuffle! if shuffle
      raise(StandardError, "shuffle broken") if my_set.size == 0
    else
      STDERR.puts("meth type is #{meth.class.to_s}")
      raise ArgumentError, "method #{meth.to_s} not recognized"
    end
    my_set
  end


  # Fractalize but build masks of this matrix (the parent) instead of building
  # whole matrices.
  # This function doesn't mess with empty row entries, only cell entries.
  def mask_fractalize_internal fold, meth, shuffle

    if meth.is_a?(String)
      raise ArgumentError, "meth is a string, but this function requires symbol :row or :cell"
    elsif meth.is_a?(Array)
      raise ArgumentError, "this function requires meth be a symbol, not an array"
    end

    divs     = split_set(set_to_fractalize(meth, shuffle), fold)
    self.build_submatrices! fold

    if meth == :cell
      (0...fold).each do |n|
        # Link masking cells to each matrix.
        puts "cell div count is #{divs[n].size}"
        divs[n].each do |cell|
          self.children[n].cells.build(:i => cell.i, :j => cell.j)
        end
      end
    elsif meth == :row
      (0...fold).each do |n|
        # Link masking cells to each matrix.
        STDERR.puts "row div count is #{divs[n].size}"
        divs[n].each do |row|
          self.cells_by_row(row).each do |cell|
            self.children[n].cells.build(:i => cell.i, :j => cell.j)
          end
        end
        # Pass information necessary for recursion to children
        self.children[n].built_rows = divs[n].dup
      end
    else
      raise ArgumentError, "Could not interpret meth (type: #{meth.class.to_s})"
    end

    self.children
  end

  # Returns n new matrices, each with (s * (n - 1) / n) items.
  # Empty rows are copied into child matrices. If deletion of cells creates new
  # empty rows, those are created in the child as well.
  def fractalize_internal fold, meth, shuffle
    # self.divisions = fold

    divs     = split_set(self.set_to_fractalize(meth, shuffle), fold)
    self.build_submatrices! fold

    if meth == :cell
      (0...fold).each do |n|
        # Get the union of all but one of the divisions.
        puts "cell union count is #{divs[n].size}"
        combine_all_but_one(divs, n).each do |cell|
          self.children[n].cells.build(:i => cell.i, :j => cell.j)
        end
      end
    elsif meth == :row
      (0...fold).each do |n|
        # Link masking cells to each matrix.
        puts "row union count is #{divs[n].size}"
        children[n].built_rows = combine_all_but_one(divs,n)
        children[n].built_rows.each do |row|
          self.cells_by_row(row).each { |cell| self.children[n].cells.build(:i => cell.i, :j => cell.j) }
        end
      end
    end

    self.children
  end

end