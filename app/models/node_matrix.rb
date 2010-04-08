# NodeMatrix is an abstraction of TreeMatrix. This type is used for a node that
# is not a leaf.
class NodeMatrix < TreeMatrix
  acts_as_tree_node :node_class_name => 'NodeMatrix', :leaf_class_name => 'LeafMatrix'
  
  # This function will return true only if we have two-stage cross-validation
  # set up for a matrix.
  #
  # It will be used when creating Experiments -- so we know when to clone them
  # and put one on each child matrix instead of just the root.
  #
  # A fundamental assumption is that the tree is balanced (that if one child has
  # 5 children, all children have 5 children) and polymorphic (NodeMatrix for nodes,
  # LeafMatrix for leaves).
  def has_grandchildren?
    return false if children.size == 0
    return false if children.first.is_a?(LeafMatrix)
    true
  end

  # This should maybe become a helper function. Simply provides a list of the
  # child matrix ids joined by commas (as a String).
  def list_children
    self.children.collect { |x| x.id }.join(", ")
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

  # Generate num nodes (training sets that may also act as test sets) for row-based
  # cross-validation.
  def generate_nodes num
    row_set = rows.dup
    row_set.shuffle!
    node_masks = split_set(row_set, num)

    res = []

    num.times do |n|

      child_node = child_nodes.create!(
        :cardinality    => n,
        :title          => make_child_title(n, num),
        :entry_info_id  => entry_info_id             )

      row_set = combine_all_but_one(node_masks, n)
      
      row_set.each do |i|
        entries.find(:all, :conditions => {:i => i}).each do |entry|
          child_node.clone_entry(entry)
        end
      end

      Rails.logger.info("Generated #{row_set.size} rows in a new sub-node of node #{id}, id #{child_node.id}")

      res << child_node
    end

    res
  end

  # Generate num leaves (test sets) for row-based cross-validation.
  def generate_leaves num
    row_set = rows.dup
    row_set.shuffle!
    masks = split_set(row_set, num)

    res = []

    num.times do |n|
      child_leaf = child_leaves.create!(
        :cardinality      => n,
        :title          => make_child_title(n, num),
        :entry_info_id  => entry_info_id             )

      row_set = masks[n]
      row_set.each do |i|
        entries.find(:all, :conditions => {:i => i}).each do |entry|
          child_leaf.clone_entry(entry)
        end
      end
      
      Rails.logger.info("Generated #{row_set.size} rows in a new leaf of node #{id}, id #{child_leaf.id}")

      res << child_leaf
    end

    res
  end

  # Use this function to run a check and print out all matrix statistics.
  # The check will confirm that all the test sets and training sets add up.
  def validate_tree
    if child_leaves.count == 0
    elsif child_nodes.count == 0
      # Simply print statistics for this matrix.
      statistics
    end
  end


protected

  # Generate two files in the current directory, one containing the row indeces,
  # the other containing the cells in the matrix.
  def make_inputs rows_filename, cells_filename, options = {}
    opts = { :file_prefix => "testset", :dest_dir => root_dir }.merge(options)
    dest_dir = opts[:dest_dir]

    written = []

    Dir.mkdir(dest_dir) unless File.exists?(dest_dir)
    Dir.chdir(dest_dir) do
      make_inputs_internal rows_filename, cells_filename

      written = write_children_using :write_rows_inverted, opts[:file_prefix]
    end
    
    written << rows_filename
    written << cells_filename
    written
  end

  # Write children to files using a specific method. That method shall be
  # responsible for determining the output format; this function handles naming
  # the file and opening and closing it.
  #
  # Returns the names of the files written.
  #
  # Example:
  #  write_children_using :write_cells_inverted, "testset"
  def write_children_using write_method_sym, file_prefix="testset"
    files_written = []
    
    Dir.chdir(root_dir) do
      children.each do |child|
        filename = child_filename_internal(file_prefix, child)
        file = File.new(filename, "w")
        child.send write_method_sym, file
        file.close
        files_written << filename
      end
    end
    files_written
  end


  def children_file_paths file_prefix
    children_filenames(file_prefix).collect { |x| root_dir + x }
  end

  
  def make_child_title n, total
    self.title + " (" + (n+1).to_s + "/" + total.to_s + ")"
  end
end


# This is how we used to do fractalization. I didn't want to delete it, in case
# we have questions about old data in the future.
#
# This is mildly buggy. I never tested cell-based fractalization, and row-based
# fractalization was actually producing a hybrid.
class OldFractalizeMethods
  # Create n random subsets of this matrix, each of size (s * (n-1 / n)). If
  # supplied with a list, repeats recursively for each of the subsets.
  # If supplied with an integer, creates subsets which are of size (s / n),
  # which serve as masks.
  #
  # n is specified by folds, which can be a Fixnum or an Array (containing Fixnum).
  #
  # By setting shuffle to false, you're telling it not to randomize the rows that
  # end up as test sets. (Having shuffle as true has no effect on the row or
  # column contents. That is handled by copy_and_randomize.)
  def fractalize(folds, shuffle=true)
    # Convert to an array even if there is only one
    folds = [folds] if folds.is_a?(Fixnum)

    # Set up the methods for fractalization -- there should be one for each of
    # the entries in the folds argument
    methods = []
    folds.each { |fold|  methods << :row  }

    fractalize_by_method(folds, methods, shuffle)
  end

  # Does the work for fractalize, but also allows cross-validation methods (row
  # or cell) to be specified. This functionality was deprecated when we couldn't
  # figure out how to do cell-based cross-validation.
  #
  # This function used to be called simply fractalize. You should use that
  # function instead.
  #
  # Note that folds and methods must both be arrays, and they must have equal
  # size.
  def fractalize_by_method(folds, methods, shuffle=true)

    unless folds.is_a?(Array) && methods.is_a?(Array) && folds.size > 0
      raise(ArgumentError,"folds and methods must be arrays of equal non-zero size")
      raise(ArgumentError, "folds and methods must be the same size") unless folds.size == methods.size
    end

    fractalize_by_method_internal(folds, methods, shuffle)
  end

  # fractalize_by_method without the error-checking.
  def fractalize_by_method_internal folds, methods, shuffle
    # Pop the top value.
    fold    = folds.shift
    meth    = methods.shift
    STDERR.puts("fold is #{fold}, meth is #{meth}")

    if folds.size >= 1
      self.fractalize_internal(fold, meth, shuffle)
      # recurse
      self.children.each do |child|
        child.fractalize_by_method_internal(folds.dup, methods.dup, shuffle)
      end
    else
      self.mask_fractalize_internal fold, meth, shuffle
    end
  end
  
  # Get the set of cells or rows to fractalize. Called only by mask_fractalize_internal
  # and fractalize_internal.
  def set_to_fractalize meth, shuffle
    my_set = nil

    if self.built_rows.size == 0
      if new_record?
        raise StandardError, "Looks like an object was built but not saved and therefore its children are hidden."
      else
        raise StandardError, "Looks like you saved an empty object and want to fractalize it, but that seems silly."
      end
    end

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