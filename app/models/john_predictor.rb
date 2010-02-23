# This class is a slight simplification of JohnExperiment. Generally, most of its
# behavior duplicates that child, and you may look at its docs for reference.
#
# The major differences:
# * This class does not perform cross-validation. It only runs the phenomatrix
#   binary on a single matrix, and produces predictions. As a result, it uses
#   fewer matrix columns and offers fewer arguments to the binary.
# * This class does not load any ROCs in after_run, since no ROCs can be calculated
#   without cross-validation.
class JohnPredictor < Experiment
  AVAILABLE_DISTANCE_MEASURES = {"Hypergeometric" => "hypergeometric",
      "Manhattan" => "manhattan",
      "Euclidean" => "euclidean"}

  validates_numericality_of :min_genes, :greater_than => 2, :only_integer => true, :allow_nil => true, :message => "should be blank for 2 or otherwise set to 3 or greater"
  validates_inclusion_of :distance_measure, :in => AVAILABLE_DISTANCE_MEASURES.values

  # Differs from JohnExperiment in that it does not copy test sets.
  # Also used by JohnDistribution.
  def prepare_inputs
    prepare_inputs_internal do

      prepare_standard_inputs

      # No need for test sets.
      # self.copy_testsets
    end
  end

  # Command line arguments for running something in the shell.
  def argument_string
    s = "-m #{self.read_attribute(:method)} -d #{self.distance_measure} -S #{self.predict_species} -s #{self.source_species_to_s} -k #{self.k} #{self.arguments} "
    s << "-x #{self.min_genes} " unless self.min_genes.nil?
    s
  end

  # Gives the filename for the set of genes that should be predicted. This file
  # differs from genes.Sp in that it only contains those rows which are have
  # associated columns (i.e., the rows which have non-zero entries). genes.Sp
  # also contains empty rows, giving the complete set of orthologs in a matrix.
  def row_filename
    "predict_" + self.predict_matrix.row_title.pluralize
  end

  # Gives the filename for the set of phenotypes that should be predicted. This
  # only includes those columns which have non-zero entries.
  def column_filename
    "predict_" + self.predict_matrix.column_title.pluralize
  end

  # Absolute path to column file.
  def column_file_path
    self.root + self.column_filename
  end

  # Absolute path to row file.
  def row_file_path
    self.root + self.row_filename
  end

  # Tests for existence of column_filename at column_file_path
  def column_file_exists?
    File.exists?(self.column_file_path)
  end

  # Tests for existence of row_filename at row_file_path
  def row_file_exists?
    File.exists?(self.row_file_path)
  end

  # Remove intermediate predictions files
  def clean_predictions_dirs
    Dir.chdir(self.root) do
      `rm -rf predictions*`
    end
  end

  # Remove intermediate distance and common items files.
  def clean_temporary_files
    Dir.chdir(self.root) do
      message "Cleaning experiment temporary files in #{self.root}"
      `rm -f *.distances *.pdistances *.common *.pcommon`
    end
  end

  # Specifies the path to the binary for performing the actual distance
  # calculations and k-nearest neighbors.
  def bin_path
    Pathname.new("/usr/local/bin/phenomatrixpp") # Rails.root + "bin/#{Socket.gethostname}/phenomatrix"
  end  

  # In the parent this is used to calculate and load ROCs. Here, we don't want
  # to do anything with it...for now. It'll be overridden again in JohnDistribution.
  def after_run
  end

protected

  # Copy the inputs from the source matrices. Returns a list of cell files so we
  # can compute the rows that we're capable of predicting (e.g., predict_genes).
  def copy_source_matrix_inputs(dir = self.root)
    message("Copying experiment source input files in #{self.root}")
    cell_files = []

    if source_matrices.size == 0      # Debug!
      STDERR.puts("Error: Experiment #{self.id} has no source matrices. Running additional checks...")
      if self.parent_id.nil?
        STDERR.puts("- no parent_id found.")
      elsif parent.source_matrices.size == 0
        STDERR.puts("- parent #{parent_id} found, has no source matrices.")
        STDERR.puts("- parent #{parent_id} has #{parent.sources.size} sources.")
        if parent.parent_id.nil?
          STDERR.puts("- no grandparent found.")
        elsif parent.parent.source_matrices.size == 0
          STDERR.puts("- grandparent found, has no source matrices.")
        else
          STDERR.puts("- grandparent found, has #{parent.parent.source_matrices.size} source matrices.")
        end
      else
        STDERR.puts("- parent found, has #{parent.source_matrices.size} source matrices.")
      end
      raise(IOError, "Experiment #{self.id} has no source matrices!")
    end

    source_matrices.each do |source_matrix|
      message(" from path: #{source_matrix.row_file_path}")
      FileUtils.cp(source_matrix.row_file_path, self.root)
      message(" from path: #{source_matrix.cell_file_path}")
      FileUtils.cp(source_matrix.cell_file_path, self.root)
      

      # Also keep track of genes files.
      cell_files << source_matrix.cell_filename
    end

    message("- done copying source input files.")
    cell_files
  end

  # Generate the file for rows to be predicted (e.g., predict_genes)
  def generate_row_file(cell_files)
    raise(ArgumentError, "No cell files supplied") if cell_files.size == 0
    
    Dir.chdir(self.root) do
      cmd = "cut -f 1 #{cell_files.join(" ")} |sort|uniq > #{self.row_filename}"
      message("Generating experiment row file in #{self.root} with command:\n #{cmd}")
      `#{cmd}`
    end
  end

  # Generate the file for columns to be predicted (e.g., predict_phenotypes).
  # This function takes into account the :min_genes property; does not request
  # prediction of phenotypes which have fewer than min_genes genes in them.
  def generate_column_file
    Dir.chdir(self.root) do
      message("Generating experiment column file in #{self.root}")
      if self.min_genes.nil? || self.min_genes == 0
        # Easy way -- just cut the cell file.
        `cut -f 2 #{self.predict_matrix.cell_file_path} |sort|uniq > #{self.column_filename}`
      else
        f = File.new(self.column_filename, "w")
        nrows_by_col = self.predict_matrix.number_of_rows_by_column
        nrows_by_col.each_pair do |col,nrows|
          f.puts(col) unless nrows < self.min_genes
        end
        f.close
      end
    end

    self.column_filename
  end
end
