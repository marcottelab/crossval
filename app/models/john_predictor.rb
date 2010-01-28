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

  def row_filename
    "predict_" + self.predict_matrix.row_title.pluralize
  end

  def column_filename
    "predict_" + self.predict_matrix.column_title.pluralize
  end

  def column_file_path
    self.root + self.column_filename
  end

  def row_file_path
    self.root + self.row_filename
  end

  def column_file_exists?
    File.exists?(self.column_file_path)
  end

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
      `rm -f *.distances *.pdistances *.common *.pcommon`
    end
  end

  def bin_path
    Rails.root + "bin/#{Socket.gethostname}/phenomatrix"
  end  

  # In the parent this is used to calculate and load ROCs. Here, we don't want
  # to do anything with it...for now. It'll be overridden again in JohnDistribution.
  def after_run
  end

protected

  # Copy the inputs from the source matrices. Returns a list of cell files so we
  # can compute the rows that we're capable of predicting (e.g., predict_genes).
  def copy_source_matrix_inputs(dir = self.root)
    cell_files = []
    self.source_matrices.each do |source_matrix|
      FileUtils.cp(source_matrix.row_file_path, self.root)
      FileUtils.cp(source_matrix.cell_file_path, self.root)

      # Also keep track of genes files.
      cell_files << source_matrix.cell_filename
    end
    cell_files
  end

  # Generate the file for rows to be predicted (e.g., predict_genes)
  def generate_row_file(cell_files)
      Dir.chdir(self.root) do
        `cut -f 1 #{cell_files.join(" ")} |sort|uniq > #{self.row_filename}`
        # `cut -f 2 #{self.predict_matrix.cell_file_path} |sort|uniq > #{self.column_filename}`
      end
  end

  # Generate the file for columns to be predicted (e.g., predict_phenotypes).
  # This function takes into account the :min_genes property; does not request
  # prediction of phenotypes which have fewer than min_genes genes in them.
  def generate_column_file
    Dir.chdir(self.root) do
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
