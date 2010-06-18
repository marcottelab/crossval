# The Matrix class encapsulates three related but essentially different sparse
# matrices, and is very purpose-specific.
#
# = Goals
# * Sparse storage
# * Multi-level tree structure for storing cross-validation training and test sets.
#
# = Usage
# == Entering Matrix Data
# This is something I haven't done in a while. I can't remember off the top of my
# head what the function is.
#
# What I can tell you, though, is you need the tables in standard phenolog format.
# You also need to keep in mind that not every gene has phenotypes associated, so
# matrices need to have the empty rows registered. There is no need to register
# empty columns.
#
# == Cross-validation
# Once you've entered matrix data (for a single matrix), if you want to cross-
# validate, you need to create n child matrices which each contain 1/n rows.
# (There is currently no way to do cell-based cross-validation, as that would
# require a non-sparse matrix format.)
#
# Child matrices can be created using the fractalize function, which takes as an
# argument the number (or numbers) of folds you want. So, to do single-stage
# cross-validation, you'd do:
#
#  matrix.fractalize 10
#
# To do two-stage five-fold cross-validation, you use:
#
#  matrix.fractalize [5,5]
#
# Don't forget to save the parent matrix after the generation of children is
# complete.
#
# WARNING: <i>Do not run fractalize more than once on a single matrix.</i> If
# you want to do multiple types of cross-validation, you need to copy the matrix
# and then save the copy -- and after that you can run fractalize on the copy.
#
# = Design
# == Tree Structure
# * Matrices in tree (TreeMatrix) are either root/branch (NodeMatrix) or leaf (LeafMatrix).
# * Root/branch matrices are stored in their entirety.
# * Leaf matrices are stored as masks of their parents (which are root/branch).
# * The different levels can be divided in different folds (e.g., both ten-fold,
#   both five-fold, or one ten and one five, for example).
# * Division of matrices is recursive, so you can have as many levels as you want.
# * If a matrix has no children or parents (i.e., it's a singleton), it is stored
#   as a root/branch.
#
# == Database Storage
# * Two classes of Entry in the database: Cell, EmptyRow (children of Entry).
# * Empty columns are not stored, as these are not required for cross-validation.
# * Empty rows mark genes which have no phenotypes in an organism.
# * An organism that lacks a gene will have no empty row.
# * When a test set is generated from a root/branch matrix, and removal of cells
#   causes a row to become empty, an EmptyRow is added to the test set matrix.
#
# == Working Directory
# Since matrix calculations occur outside of the Rails environment -- typically
# as binaries or scripts executed through the shell -- matrices must be output
# to the filesystem.
#
# The function `prepare_inputs` is responsible for initializing the working
# directory, which is in `crossval/tmp/work`.
#
# Each root/branch matrix has its own working directory in `tmp/work`, with the
# directory name consisting of 'matrix_' followed by the unique ID for the
# matrix. For example, the Human non-random matrix is `tmp/work/matrix_1/`.
#
# The matrix directory includes, at a bare minimum:
# * `genes.Sp`, a list of the unique rows in the matrix (typically by Entrez
#   human gene ID)
# * `genes_phenes.Sp`, a list of the cells in the matrix. The format of this
#   matrix is one line per cell, with the row (gene ID) in the first table column
#   and the column (phenotype ID) in the second table column.
#
# Note that Sp represents the species abbreviation, e.g., 'Hs'. If the matrix is
# a randomization, the suffix will be Spr, e.g., 'Hsr'.
#
# In addition, if test sets have been generated for the matrix, these will be
# given by the identifier `testset.`; followed by the number of children
# (immediate descendents) the matrix has; a dash; and the number of this
# particular test set (starting at 0). For example, matrix 1 has `testset.10-0`
# through `testset.10-9`. Each test set is formatted in the same way as
# `genes_phenes.Sp`.
#
# == Subdirectories
# Each matrix working directory may contain multiple sub-directories which
# function as working directories for experiments. These are named in the same
# manner as matrix working directories, e.g., `experiment_1` for the Experiment
# with database ID 1.
#
# The contents of these directories are given in the docs for the Experiment
# class (and its children as appropriate).
class Matrix < ActiveRecord::Base
  acts_as_commentable # not required, strictly speaking.

  belongs_to :entry_info
  has_many :empty_rows, :dependent => :destroy
  has_many :cells, :dependent => :destroy
  has_many :entries, :dependent => :destroy
  has_many :experiments, :foreign_key => :predict_matrix_id

  named_scope :by_row_species, lambda { |s| { :conditions => { :row_species => s } } }

  delegate :row_title, :to => :entry_info
  delegate :column_title, :to => :entry_info

  def integrators; self.experiments.by_type('Integrator'); end
  def john_experiments; self.experiments.by_type('JohnExperiment'); end
  def john_predictors; self.experiments.by_type('JohnPredictor'); end
  def john_distributions; self.experiments.by_type('JohnDistribution'); end

  FULL_SPECIES_NAME = {'Hs' => "Homo sapiens", 'At' => "Arabidopsis thaliana" }

  # Get a hash of statistics on this matrix.
  def statistics
    h = {}
    h["DB cells"] = Cell.count(:conditions => ["matrix_id = ?",id])
    h["DB entries"] = Entry.count(:conditions => ["matrix_id = ?",id])
    h["DB empty_rows"] = EmptyRow.count(:conditions => ["matrix_id = ?",id])
    h
  end

  # A descriptor which uniquely identifies a matrix, useful for drop-down boxes
  # particularly when title is the same for multiple matrices.
  # In this case, it's the ID and the title.
  def unique_descriptor
    "#{self.id}: #{self.title}"
  end

  # Calls destroy, but first deletes the matrix directory on the filesystem.
  def destroy_borked
    FileUtils.rm_rf(root_dir) if root_dir.to_s.include?(Matrix.work_root)
    destroy
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


  # Order the columns by the number of rows and build as a list of lists, for
  # plotting with flotomatic.
  def row_distribution
    num_rows_by_col = self.number_of_rows_by_column.values.sort
    num_rows_by_col.each_index do |i|
      val = num_rows_by_col[i]
      num_rows_by_col[i] = [i, val]
    end
    num_rows_by_col
  end


  # Get all columns or all columns with row <i>i</i>.
  def column_indeces(i = nil)
    self.indeces_by_row_or_column(:i, :j, i)
  end

  # Get all row indeces or, if an arg <i>j</i> is provided, all those with column <i>j</i>.
  def rows(j = nil)
    indeces_by_row_or_column(:j, :i, j)
  end

  # This gets overridden by TreeMatrix: all_rows points to the parent, and rows
  # stays the same.
  alias_method :all_rows, :rows

  
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
      entries.collect { |c| c.send other_sym }.uniq.reject { |c| c.nil? }
    else
      entries.find(:all, :conditions => {sym => val}).collect { |c| c.send other_sym }.uniq.reject { |c| c.nil? }
    end
  end

  # Phenolog-specific function.
  # Prepare working directory for all matrices and their experiments.
  def self.prepare_inputs
    Matrix.all.each do |m|
      m.prepare_inputs unless m.is_a?(LeafMatrix)
    end

    # Only create experiments after matrices have been created
    Matrix.all.each do |m|
      m.experiments.each { |exp| exp.prepare_inputs } unless m.is_a?(LeafMatrix)
    end
  end

  # Phenolog-specific function.
  # Prepare working directory for the matrix.
  # If force is set to true, the contents will be overwritten.
  def prepare_inputs(force = false)
    make_inputs(row_filename, cell_filename) unless root_exists? && !force
  end

  def row_filename
    entry_info.row_filename(self.column_species)
  end

  def row_file_path
    root_dir + row_filename
  end

  def cell_filename
    # This seems counter-intuitive, but it is correct. Hopefully.
    entry_info.cell_filename(self.column_species)
  end

  def cell_file_path
    root_dir + cell_filename
  end

  # Use this when displaying the matrix, e.g. through Rails.
  def cells_for_display(res = {})
    self.cells.each do |entry|
      res[entry.to_s(":")] = CellValue.new(false)
    end

    res
  end


  # Gives the number of rows in the root of the tree of matrices. That means if
  # this is a cross-validation submatrix, we return the root's row count.
  def number_of_rows
    row_count
  end


  # If this is true, we can run a meta-analysis (the second-stage crossvalidation).
  def children_have_been_run?
    res = true
    res = false  if self.children.size == 0

    self.children.each do |child|
      res &&= child.has_been_run?
      return res unless res
    end
    
    res
  end

  # Returns true if all experiments have been run for a matrix.
  def has_been_run?
    res = true
    res = false  if self.experiments.size == 0

    self.experiments.each do |experiment|
      res &&= experiment.has_been_run?
      return res unless res
    end

    res
  end


  # Creates a new matrix from two files, one consisting of a list of rows, and
  # the other a list of cells with true values.
  def self.create_from_file_pair!(row_filename, cell_filename, attributes = {})
    m = self.create_from_file!(row_filename, attributes)
    m.read_entries_from_file!(cell_filename)
    m
  end

  # Calls create_from_file_pair! for each pair of filenames.
  # In each pair should be a row file and a cell file.
  # Returns the matrices that were created.
  def self.create_from_file_pairs!(row_and_cell_filenames)
    matrices = []
    row_and_cell_filenames.each do |file_pair|
      matrices << Matrix.create_from_file_pair!(file_pair[0], file_pair[1])
    end
    matrices
  end


  # Creates a new matrix from a file (path/string, not stream).
  # File should contain either a list of rows or a set of pairs which denote cells
  # with true values.
  # In certain cases, these cells can also mask a parent matrix -- namely, if this
  # matrix itself has no children, but does have a parent.
  def self.create_from_file!(filename, attributes = {})
    
    # Infer as much information as possible.
    attributes[:row_species] = (infer_species_from_filename(filename.to_s) || "Hs") unless attributes.has_key?(:row_species)
    attributes[:column_species] = "Hs" unless attributes.has_key?(:column_species)
    attributes[:entry_info_id] = EntryInfo.find_or_create!("gene", "phenotype").id unless attributes.has_key?(:entry_info_id)
    attributes[:title] = filename.to_s unless attributes.has_key?(:title)
    
    m = Matrix.create!(attributes)
    m.read_entries_from_file!(filename)
    m
  end

  # Creates several new matrices from a series of files.
  def self.create_from_files!(list_of_files)
    res = []
    list_of_files.each do |file|
      res << Matrix.create_from_file!(file)
    end
    res
  end

  # Given a file stream or filename, read into this matrix.
  def read_entries_from_file!(file)
    if file.is_a?(String) || file.is_a?(Pathname)
      read_entries_from_open_file!(File.new(file, "r"))
    elsif file.is_a?(File)
      read_entries_from_open_file!(file)
    else
      raise ArgumentError, "Expected filename or file as argument"
      false
    end
  end

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


  # Write all row indeces to a file.
  def write_rows!(file)
    save! if changed?
    file = File.new(file, "w") if file.is_a?(String) || file.is_a?(Path)
    write_rows(file)
  end

  # Write a single matrix's row indeces.
  def write_rows(file)
    rows.each do |entry|
      file.puts entry
    end
  end

  # Write a single matrix, not its children.
  def write(file, options = {})w
    opts = self.write_options options
    
    if self.changed?
      raise NotImplementedError, "Need to save the matrix before trying to write its contents. Call write! instead if you want to force a save."
    else
      self.write_saved(file, opts)
    end
  end

  # Depends on entry_infos -- genes and phenotypes as the row and column titles
  # indicate phenomatrix.
  def is_phenomatrix?
    self.entry_info.row_title == "gene" && self.entry_info.column_title == "phenotype"
  end

  # Force a save before writing; otherwise, same as write
  def write!(file, options = {})
    opts = self.write_options options
    
    self.save! if self.changed?
    self.write_saved(file, opts)
  end


  def children_filenames file_prefix
    l = []
    #if self.children.first.mask?
      self.children.each do |child|
        l << self.child_filename_internal(file_prefix, child)
      end
    #end
    l
  end

  
  def has_experiments_to_run?
    self.experiments.not_run.count > 0
  end

  
  # Get the number of stages of cross-validation this matrix is set up for.
  def stages
    return 0 if self.children.count == 0
    self.children.first.stages + 1 # recursive.
  end

  def self.root_dir
    Rails.root + "tmp/work"
  end
  class <<self; alias_method :work_root, :root_dir; end

  def root_dir
    self.class.work_root + "matrix_#{self.id}"
  end

  def dir_exists? dir
    File.exists?(dir)
  end

  def root_exists?
    dir_exists?(root_dir)
  end

  # List files and dirs in the matrix directory
  def ls
    if root_exists?
      Dir.entries(root_dir).reject { |e| e == "." || e == ".." }
    else
      STDERR.puts("ls: cannot access #{root_dir}: No such file or directory")
      nil     
    end
  end

protected

  # Generate two files in the current directory, one containing the row indeces,
  # the other containing the cells in the matrix.
  def make_inputs rows_filename, cells_filename, options = {}
    opts = {:dest_dir => root_dir }.merge(options)
    dest_dir = opts[:dest_dir]

    Dir.mkdir(dest_dir) unless File.exists?(dest_dir)
    Dir.chdir(dest_dir) do
      make_inputs_internal rows_filename, cells_filename
    end
    [rows_filename,cells_filename]
  end

  # Used for returning either row or column of every entry corresponding to this matrix.
  def unique_entry_value_sql(field, count = false)
    sql = "SELECT "
    if count
      sql << "COUNT(DISTINCT #{Entry.table_name}.#{field}) "
    else
      sql << "DISTINCT #{Entry.table_name}.#{field} "
    end
    sql << <<SQL
FROM #{Matrix.table_name}
INNER JOIN #{Entry.table_name} ON (#{Entry.table_name}.matrix_id = #{Matrix.table_name}.id)
WHERE #{Matrix.table_name}.id = #{self.id}
SQL
    sql
  end

  #
  def unique_vector_sql(field, at, count = false)
    vf = field == "i" ? "j" : "i"
    sql = self.unique_entry_value_sql(field, count)
    sql << " AND #{Entry.table_name}.#{vf} = #{at}"
    sql
  end


  def make_inputs_internal rows_filename, cells_filename
    rows_file = File.new(rows_filename,  "w")
    write_rows  rows_file
    rows_file.close

    cells_file = File.new(cells_filename, "w")
    write_cells cells_file
    cells_file.close

    [rows_filename, cells_filename]
  end
  
  def unique_row_sql(count = false)
    unique_entry_value_sql("i", count)
  end

  def unique_column_sql(count = false)
    unique_entry_value_sql("j", count)
  end


  # Returns the default options for write() and the functions it calls.
  def write_options options = {}
    {
      :header => false
    }.merge options
  end

  # See write_saved
  def write_saved_rows file
    writelines(file, self.unique_rows)
  end

  # Use this to force writing of a matrix that has already been saved. It may work
  # with an unsaved file, but behavior could be unpredictable and it would likely
  # be a bad idea.
  def write_saved(file, options)
    
    f = file
    f = File.new(file, "w") if file.is_a?(String) || file.is_a?(Pathname)

    # write the header
    f.puts(matrix_info.to_s) if options[:header]

    write_cells(f, options)

    f.close
    f.path
  end


  # Write the cells of the matrix.
  def write_cells(open_file)
    STDERR.puts("write_cells in matrix.rb")
    cells.each do |entry|
      entry.write(open_file)
    end
    open_file
  end

  def cells_by_row i
    self.cells.find(:all, :conditions => {:i => i})
  end


  def find_or_create_cell!(i, j)
    Cell.find_or_create!(i, j, self.id)
  end

  def create_empty_row!(i)
    self.empty_rows.create!(:i => i)
  end

  def update_row_count
    self.row_count = self.count_unique_rows
  end

  def update_row_count!
    self.update_row_count
    self.save!
  end

  def update_column_count
    self.column_count = self.count_unique_columns
  end

  def update_column_count!
    self.update_column_count
    self.save!
  end


  # Read a list of cells or rows. If a single entry in a line, it's an empty row
  # (meaning no cells in that row). If two entries, it's a cell with a true value
  # in it.
  def read_entries_from_open_file!(file)
    while line = file.gets
      line.chomp!
      fields = line.split("\t")

      if fields.size == 1 # List of rows.
        # Create a row.
        self.create_empty_row!(fields[0])
      else
        # Convert a row to a cell (or just create a cell).
        self.find_or_create_cell!(fields[0].to_i, fields[1].to_i)
      end
    end

    self.update_column_count!
    self.update_row_count!
  end

end


# opposite of readlines. Not sure why it even needs to be added here, should
# be built in.
def writelines(path, data)
  path.is_a?(File) ? path.puts(data) : File.open(path, "wb") { |file| file.puts(data) }
end

# See if we can infer species information from the filename.
def infer_species_from_filename fn
  fields = fn.split(".")
  fields.last =~ /^[A-Z][a-z]{1,2}$/ ? fields.last : nil
end


