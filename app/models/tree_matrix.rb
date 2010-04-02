# This Matrix subclass is used for creating a hierachy of matrices, where some
# mask others.
#
# NodeMatrix and LeafMatrix inherit from TreeMatrix. NodeMatrix is for root and
# branch nodes (that aren't leaves). LeafMatrix is for leaf nodes, which are
# designed to more efficiently store cross-validation information as masks.
class TreeMatrix < Matrix

protected

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
      rows
    end
  end
end