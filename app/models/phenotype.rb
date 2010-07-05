class Phenotype < ActiveRecord::Base
  has_many :entries, :foreign_key => :j

  def update_observations matrix, entries_param 

    # Do not update if matrix is a tree matrix. It's simply too complicated.
    return false if matrix.is_a?(TreeMatrix)

    # This stores the rows the user entered.
    rows_at_completion = []
    
    entries_param.split("\n").each do |gene|
      gene.strip!
      STDERR.puts 'gene is ' + gene + '*'
      if !gene.is_positive_integer?
        self.errors.add_to_base("Gene #{gene} does not appear to be an Entrez gene ID")
        next
      end

      gene = gene.to_i

      # Attempt to determine whether this matrix permits the given row.
      entry = matrix.entries.find_by_i(gene)
      if entry.nil?
        self.errors.add_to_base("Gene #{gene} not recognized for this matrix.")
      else
        rows_at_completion << gene
      end
    end

    # If there were no errors, attempt to make the change.
    if self.errors.size == 0
      rows_at_completion.sort!

      Matrix.transaction do
        matrix.lock!

        rows_in_column = Set.new(matrix.entries.find(:all, :conditions => {:j => self.id}, :lock => true).collect{ |e| e.i }.sort.uniq)
        rows_at_completion.each do |row|

          # Attempt to convert EmptyRow to Cell
          e = matrix.empty_rows.find(:first, :conditions => {:i => row}, :lock => true)
          unless e.nil?
            Entry.update_all( "type = 'Cell', j = #{self.id}", ["i = ? AND matrix_id = ? AND type = ?", row, matrix.id, 'EmptyRow'])
            Matrix.update_all( "cell_count = #{matrix.cell_count + 1}", ["id = ?", matrix.id])
            # STDERR.puts("Increment")
            # matrix.cell_count += 1
          end

          # Reload as Cell, or create it
          e = matrix.cells.find(:first, :conditions => {:i => row, :j => self.id, :matrix_id => matrix.id, :type => 'Cell'}) if e.nil?
          e = matrix.cells.create!(:i => row, :j => self.id) if e.nil?

          # Note that we've added the row at this point
          rows_in_column << e.i
        end

        # Now take care of rows that we want to remove
        rows_to_remove = rows_in_column - rows_at_completion
        rows_to_remove.each do |row|
          cells_in_row = matrix.cells.find_all_by_i(row).count

          if cells_in_row == 0
            raise ArgumentError, "Error: Invalid row #{row} does not exist in matrix #{matrix.id}"

          elsif cells_in_row == 1
            e = matrix.cells.find(:first, :conditions => {:i => row, :j => self.id}, :lock => true)
            Entry.update_all( "type = 'EmptyRow', j = NULL", ["i = ? AND matrix_id = ? AND type = ?", row, matrix.id, 'Cell']) unless e.nil?
            Matrix.update_all( "cell_count = #{matrix.cell_count - 1}", ["id = ?", matrix.id])
            # STDERR.puts("Decrement")
            # matrix.cell_count -= 1
            
          else
            # Simply remove the cell
            matrix.cells.find(:first, :conditions => { :i => row, :j => self.id }, :lock => true).destroy
          end
        end

        if rows_at_completion.size == 0
          Matrix.update_all( "column_count = #{matrix.column_count - 1}", ["id = ?", matrix.id])
        elsif rows_in_column == 0
          Matrix.update_all( "column_count = #{matrix.column_count + 1}", ["id = ?", matrix.id])
        end

        matrix.save!
      end # END TRANSACTION

      # Force reload of the matrix in the cache.
      matrix.uncache if matrix.is_cached?

      true
    else
      false
    end
  end
end
