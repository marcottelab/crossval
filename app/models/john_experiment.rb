# This class is for running cross-validation using phenomatrix++.
#
# = Preparing to Run
# To prepare the binary, you'll want to go to crossval/bin/<machinename>/ and run
#  ~/../../../phenomatrixpp/configure
#  make
#  cp src/phenomatrix .
#
# These commands will compile and link phenomatrix, and put it in the correct
# location. Do the same for both lovelace and draco (in place of <machinename>).
#
# These instructions also apply to JohnPredictor and JohnDistribution.
#
# = Preparing inputs
# To prepare inputs for cross-validation (or for JohnPredictor and JohnDistribution),
# use the prepare_inputs function on the specific experiment (after preparing the
# matrices).
#
# JohnExperiment differs from JohnPredictor in that it also copies the test sets
# for the Matrix into the Experiment working directory.
#
# = Outputs
# JohnExperiment also sorts multiple predictions directories (setup in after_run)
# into the results.timestamp directory. These outputs are described in Experiment's docs.
#
# Finally,
#
# = Notes
# * The only setting that currently works for validation_type is row. We never figured
#   out cell cross-validation for sparse matrices. You'd need to find a more efficient
#   way to store matrices (not sparse, and likely not in the database).
# * method is a reserved function in Rails or maybe Ruby, so we have to be specific
#   that we're messing with the attribute :method in many places. This is why we
#   call read_attribute(:method) to get its value instead of simply self.method.
# * In the development and production databases (currently), each column should have
#   at least two entries in it. This is equivalent to setting min_genes = 2, but
#   I recommend setting min_genes to nil if you want that. If you want a higher
#   min_genes, go ahead and set it higher than 2. Actually, it won't accept 2 or lower.
# * The number of cross-validation steps to run is set by the number of children
#   the predict_matrix has.
class JohnExperiment < JohnPredictor

  AVAILABLE_METHODS = {"Naive Bayes (JOW)" => "naivebayes", "Partial Bayes (JOW)" => "partialbayes"}

  validates_numericality_of :k, :greater_than => 0, :only_integer => true, :message => "should be greater than 0"  
  validates_inclusion_of :method, :in => AVAILABLE_METHODS.values
  validates_inclusion_of :validation_type, :in => ['row', 'cell']

  # Command line arguments for running something in the shell.
  def argument_string
    s = "-m #{method} -d #{self.distance_measure} -n #{self.predict_matrix.children.count} -S #{self.predict_species} -s #{self.source_species_to_s} -t #{self.validation_type} -k #{self.k} #{self.arguments} "
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

