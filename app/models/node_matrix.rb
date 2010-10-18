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

  # See method has_grandchildren? for an explanation.
  def has_great_grandchildren?
    has_grandchildren? ? children.first.has_grandchildren? : false
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
    col_count   = target.column_count

    while col_count == 0
      target    = target.parent
      col_count = target.column_count
    end

    (self.cells.count / col_count.to_f).round
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
  def make_inputs options = {}
    opts = { :file_prefix => "testset", :dest_dir => root_dir }.merge(options)
    dest_dir = opts[:dest_dir]

    written = []

    Dir.mkdir(dest_dir) unless File.exists?(dest_dir)
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
