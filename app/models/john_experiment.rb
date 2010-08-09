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

  validates_numericality_of :k, :greater_than => 0, :only_integer => true, :message => "should be greater than 0"  

  def run_analysis
    begin
      self.package_version = "Fastknn #{Fastknn::VERSION}"
      Fastknn.crossvalidate self.predict_matrix_id, self.source_matrix_ids, (self.min_genes || 2), self.distance_measure.to_sym, self.classifier_parameters, Dir.pwd
    rescue ArgumentError
      self.run_result = 1
    rescue => e
      logger.error(e.backtrace.join("\n"))
      self.run_result = 2
    else
      self.run_result = 0
    end
  end

  def after_run
    sort_results_and_calculate_rocs!
  end

  def before_run
    prepare_inputs
  end

end

