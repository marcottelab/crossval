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
  validates_numericality_of :max_distance, :greater_than => 0.0, :less_than_or_equal_to => 1.0, :only_integer => false, :allow_nil => true, :message => "should be positive and less than 1.0"
  validates_inclusion_of :distance_measure, :in => AVAILABLE_DISTANCE_MEASURES.values

  def setup_analysis
    self.package_version = "Fastknn #{Fastknn::VERSION}"

    classifier_parameters = {
      :classifier => self.read_attribute(:method).to_sym,
      :k => self.k,
      :max_distance => 1.0
    }
    # If the user has set a max distance, use that instead of 1.0
    classifier_parameters[:max_distance] = self.max_distance unless self.max_distance.nil?

    Fastknn::DistanceMatrix.new self.predict_matrix_id, self.source_matrix_ids, self.distance_measure, classifier_parameters
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

    self.clean_predictions_dirs
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
