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
      "Euclidean" => "euclidean",
      "Jaccard" => "jaccard",
      "Sorensen" => "sorensen",
      "Cosine similarity" => "cosine",
      "Tanimoto coefficient" => "tanimoto" }
  AVAILABLE_METHODS = {"Naive Bayes" => "naivebayes"}

  validates_numericality_of :min_genes, :greater_than_or_equal_to => 2, :only_integer => true, :allow_nil => true, :message => "should be at least 2"
  validates_numericality_of :max_distance, :greater_than => 0.0, :less_than_or_equal_to => 1.0, :only_integer => false, :allow_nil => true, :message => "should be positive and less than 1.0"
  validates_inclusion_of :method, :in => JohnPredictor::AVAILABLE_METHODS.values, :message => "method '{{value}}' is not specified"
  validates_inclusion_of :distance_measure, :in => JohnPredictor::AVAILABLE_DISTANCE_MEASURES.values, :message => "distance function '{{value}}' is not specified"

  def classifier_parameters
    cp = {
      :classifier => self.read_attribute(:method).to_sym,
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
    dm.min_idf = self.idf_threshold
    dm
  end

  def run_analysis
    begin
      analysis = setup_analysis
      analysis.predict_and_write_all # no cross-validation
    rescue ArgumentError
      self.run_result = 1
    rescue
      self.run_result = 2
    end
    self.run_result = 0
  end

  # Differs from JohnExperiment in that it does not copy test sets.
  # Also used by JohnDistribution.
  def prepare_inputs
    STDERR.puts("in prepare_inputs on #{self.class.to_s} (defined in JohnPredictor)")
    prepare_inputs_internal do

      prepare_standard_inputs

      # No need for test sets.
      # self.copy_testsets
    end
  end

  def reset_for_new_run!
    self.started_at   = nil
    self.completed_at = nil
    self.run_result   = nil
    self.total_auc    = nil
    self.save!

    begin
      self.clean_predictions_dirs
    rescue Errno::ENOENT
      Rails.logger.error("reset_for_new_run! was unable to remove non-existent directory")
    end
  end
  

  # Remove intermediate predictions files
  def clean_predictions_dirs
    Dir.chdir(self.root) do
      `rm -rf predictions*`
    end
  end


  # In the parent this is used to calculate and load ROCs. Here, we don't want
  # to do anything with it...for now. It'll be overridden again in JohnDistribution.
  def after_run
  end

  def argument_string
    "#{self.predict_matrix_id} <- [#{self.source_matrix_ids.join(", ")}] by #{self.distance_measure} using #{self.read_attribute(:method)} (k=#{self.k}, max_distance=#{self.max_distance || 1.0})"
  end

protected
  def prepare_standard_inputs
  end

end
