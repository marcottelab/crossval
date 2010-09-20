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
class KnnExperiment < Experiment

  AVAILABLE_DISTANCE_MEASURES = {"Hypergeometric" => "hypergeometric",
      "Manhattan" => "manhattan",
      "Euclidean" => "euclidean",
      "Jaccard" => "jaccard",
      "Sorensen" => "sorensen",
      "Cosine similarity" => "cosine",
      "Tanimoto coefficient" => "tanimoto",
      "Pearson correlation" => "pearson" }

  AVAILABLE_METHODS = {"Naive Bayes" => "naivebayes", "Average" => "average", "Simple" => "simple"}

  validates_numericality_of :max_distance, :greater_than => 0.0, :less_than_or_equal_to => 1.0, :only_integer => false, :allow_nil => true, :message => "should be positive and less than 1.0"
  validates_numericality_of :min_idf, :greater_than_or_equal_to => 0.0, :only_integer => false
  validates_numericality_of :distance_exponent, :only_integer => false
  validates_inclusion_of :method, :in => AVAILABLE_METHODS.values, :message => "method '{{value}}' is not specified"
  validates_inclusion_of :distance_measure, :in => AVAILABLE_DISTANCE_MEASURES.values, :message => "distance function '{{value}}' is not specified"
  validates_numericality_of :k, :greater_than => 0, :only_integer => true, :message => "should be greater than 0"

  def classifier_parameters
    {
      :classifier => self.method.to_sym,
      :k => self.k,
      :max_distance => self.max_distance || 1.0,
      :distance_exponent => self.distance_exponent || 1.0
    }
  end

  def setup_analysis
    self.package_version = "Fastknn #{Fastknn::VERSION}"

    dm = Fastknn.fetch_distance_matrix self.predict_matrix_id, self.source_matrix_ids, (self.min_genes || 2)
    dm.distance_function = self.distance_measure.to_sym
    dm.classifier = self.classifier_parameters
    dm.min_idf = self.min_idf
    dm
  end

  def run_analysis
    begin
      update_package_version! "Fastknn #{Fastknn::VERSION}"
      Fastknn.crossvalidate self.predict_matrix_id, self.source_matrix_ids, (self.min_genes || 2), self.distance_measure.to_sym, (self.min_idf || 0.0), self.classifier_parameters, Dir.pwd
    rescue ArgumentError
      update_run_result! 1
    rescue => e
      logger.error(e.backtrace.join("\n"))
      update_run_result! 2
    else
      update_run_result! 0
    end
  end

  def after_run
    sort_results_and_calculate_results!
  end

  def before_run
    prepare_inputs
  end

protected
  # Don't need to do anything for prepare_standard_inputs -- Fastknn gets stuff
  # from database on its own, without intermediate files.
  def prepare_standard_inputs
  end

end

