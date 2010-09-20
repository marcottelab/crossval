module Acts
  module Phenomatrix
    module InstanceMethods

      # This is essentially a matrix slice function.
      #
      # If you want column indeces, give it :i, :j. If you want row indeces, give it
      # :j, :i. The third argument is the row or column index you want.
      #
      # If you provide no third argument, it'll return all unique columns or rows, I think,
      # but I can't remember why I wrote it this way. Play around with it.
      #
      # Also note that this slice function is not properly overridden on LeafMatrices.
      # It will give you the mask contents, which might be the complement of what you
      # expect.
      def indeces_by_row_or_column(sym, other_sym, val = nil)
        if val.nil?
          self.entries.collect { |c| c.send other_sym }.uniq.reject { |c| c.nil? }
        else
          self.entries.find(:all, :conditions => {sym => val}).collect { |c| c.send other_sym }.uniq.reject { |c| c.nil? }
        end
      end

      # Get all row indeces or, if an arg <i>j</i> is provided, all those with column <i>j</i>.
      def row_ids(j = nil)
        indeces_by_row_or_column(:j, :i, j)
      end
      alias_method :gene_ids, :row_ids
      alias_method :rows, :row_ids
      alias_method :all_rows, :row_ids

      # Get all columns or all columns with row <i>i</i>.
      def column_ids(i = nil)
        self.indeces_by_row_or_column(:i, :j, i)
      end
      alias_method :column_indeces, :column_ids

      # Get a list of unique rows in the matrix.
      def unique_rows
        Matrix.connection.select_values(self.unique_row_sql).collect { |x| x.to_i }
      end
      alias :uniq_rows :unique_rows

      # Get unique columns in the matrix (identical to unique_rows, but columns instead).
      def unique_columns
        Matrix.connection.select_values(self.unique_column_sql).collect { |x| x.to_i }
      end
      alias :uniq_columns :unique_columns
      alias :uniq_cols    :unique_columns
      alias :unique_cols  :unique_columns

      def unique_rows_by_column(which_j)
        Matrix.connection.select_values(self.unique_vector_sql(:i, which_j)).collect { |x| x.to_i }
      end

      def count_unique_rows_by_column(which_j)
        Matrix.connection.select_values(self.unique_vector_sql(:i, which_j, true)).first
      end

      def unique_columns_by_row(which_i)
        Matrix.connection.select_values(self.unique_vector_sql(:j, which_i)).collect { |x| x.to_i }
      end

      def count_unique_rows_by_column(which_i)
        Matrix.connection.select_values(self.unique_vector_sql(:j, which_i, true)).first
      end

      def count_unique_columns
        Matrix.connection.select_values(self.unique_column_sql(true)).first.to_i
      end

      def count_unique_rows
        Matrix.connection.select_values(self.unique_row_sql(true)).first.to_i
      end

      # Make a copy of the matrix in memory.
      # This also copies all of the cells and empty rows in the matrix.
      #
      # Do not attempt to use it on a test set. This behavior is not tested.
      #
      # Note that the matrix returned will not yet be saved.
      #
      # This will not copy sub-ordinates of the matrix (such as experiments).
      def copy
        matrix_copy = self.clone
        matrix_copy.title = self.title + " copy"
        self.cells.each do |cell|
          matrix_copy.cells.build(cell.attributes.delete_if { |k,v| k == "matrix_id"})
        end
        self.empty_rows.each do |empty_row|
          matrix_copy.empty_rows.build(empty_row.attributes.delete_if { |k,v| k == "matrix_id"})
        end
        matrix_copy
      end

      # Makes an empty matrix with the same number of rows as the original in memory,
      # but does not save it.
      #
      # Since the matrix is stored in row format, no guarantee is made about the
      # number of columns.
      #
      # This function is called by copy_and_randomize.
      def make_empty_copy uqr = nil
        matrix_copy = self.clone
        matrix_copy.title = self.title + " copy"

        # Get the rows and columns
        uqr = self.unique_rows if uqr.nil?

        # First create empty rows
        uqr.each do |row|
          matrix_copy.empty_rows.build(:i => row)
        end
        matrix_copy.row_count    = uqr.size
        matrix_copy.column_count = 0
        matrix_copy
      end

      # Note that this function only works for very sparse matrices. Once columns
      # start to be dense enough for lots of collisions, this gets exponentially
      # slower.
      def copy_and_randomize
        # Get the rows and columns
        uqr = self.unique_rows

        # Make an empty copy and to help it along give it the rows (one less db op)
        matrix_copy = self.make_empty_copy uqr
        matrix_copy.title = self.title + "r"
        matrix_copy.column_species = self.column_species + "r"
        matrix_copy.conjugate_id = self.id

        # Now we have to save the copy in order to do the randomization.
        matrix_copy.save!

        # Now go through and
        self.number_of_rows_by_column.each_pair do |col, num|

          rand_column_contents = Set.new
          # draw num from uqr for this column
          while rand_column_contents.size < num
            rand_column_contents << uqr[rand(uqr.size)]
          end

          rand_column_contents.each do |row|
            matrix_copy.find_or_create_cell!(row, col)
          end
        end

        # Now save the matrix copy and update the column count
        matrix_copy.update_column_count!
        matrix_copy
      end

      # Gives a metric describing the number of cells in the matrix as a fraction of
      # the size -- in terms of the number of cells per column.
      def density
        (self.cell_count / column_count.to_f).round
      end

      # Get a hash of the column identifiers to the number of rows that have non-zero
      # values in that column.
      def number_of_rows_by_column
        num_rows_by_column = {}
        Matrix.connection.select_rows(<<SQL
SELECT j, COUNT(DISTINCT entries.i) AS count_i FROM matrices
INNER JOIN entries ON (entries.matrix_id = matrices.id)
WHERE entries.type = 'Cell' AND matrices.id = #{self.id} GROUP BY j
SQL
        ).each do |row|
          num_rows_by_column[row[0].to_i] = row[1].to_i
        end
        num_rows_by_column
      end

    end
  end
end
