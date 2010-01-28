class JohnExperiment < JohnPredictor

  AVAILABLE_METHODS = {"Naive Bayes (JOW)" => "naivebayes", "Partial Bayes (JOW)" => "partialbayes"}

  validates_numericality_of :k, :greater_than => 0, :only_integer => true, :message => "should be greater than 0"  
  validates_inclusion_of :method, :in => AVAILABLE_METHODS.values
  validates_inclusion_of :validation_type, :in => ['row', 'cell']

  # Command line arguments for running something in the shell.
  def argument_string
    s = "-m #{self.read_attribute(:method)} -d #{self.distance_measure} -n #{self.predict_matrix.children.count} -S #{self.predict_species} -s #{self.source_species_to_s} -t #{self.validation_type} -k #{self.k} #{self.arguments} "
    s << "-x #{self.min_genes} " unless self.min_genes.nil?
    s
  end

  def after_run
    sort_results_and_calculate_rocs!
  end

protected

  # Prepare the input files including cross-validation/test-set information.
  def prepare_standard_inputs
    super
    copy_testsets
  end

end

