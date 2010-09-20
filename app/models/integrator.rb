class Integrator < Experiment
  has_many :integrands, :foreign_key => :integrator_id, :dependent => :destroy
  has_many :experiments, :through => :integrands

  accepts_nested_attributes_for :integrands, :allow_destroy => true

  # Make sure sources are valid
  validates_associated :integrands

  alias :metric :method

  # This method has already been aliased to this_sources in Experiment.
  def sources
    s = Set.new
    experiments.each { |experiment| s.merge(experiment.sources) }
    s.to_a
  end

  # This method has already been aliased to this_source_matrices in Experiment.
  def source_matrices
    a = []
    experiments.each { |experiment| a.concat(experiment.source_matrices) }
    a.active_record_uniq
  end

  # This method has been aliased to this_source_matrix_ids in Experiment
  def source_matrix_ids
    a = Set.new
    experiments.each { |experiment| a.merge(experiment.source_matrix_ids) }
    a.to_a
  end

  def title
    "Basic integrator (#{id})"
  end

  def distance_measure
    self.class.to_s.tableize.singularize.humanize.downcase
  end

  def package_version
    versions = experiments.collect{ |x| x.package_version }.sort.uniq
    if versions.size == 1
      versions
    else
      "Various"
    end
  end

protected

  # No children for integrators -- unless we're doing three-stage or more.
  def prepare_children
    if predict_matrix.is_a?(NodeMatrix) && predict_matrix.has_great_grandchildren?
      create_children
    else
      nil
    end
  end

  # Just make sure children have been run successfully (test called before allowing
  # a parent experiment to be run).
  def check_integrands_before_run
    if integrands.count > 0
      integrands(:joins => :experiments).each do |integrand|
        raise(StandardError, "Integrands must be run first") unless integrand.experiment.has_run_successfully?
      end
    end
  end

  def before_run
    check_integrands_before_run
    prepare_inputs
  end

  def after_run
    sort_results_and_calculate_results!
  end


  def prepare_standard_inputs
  end
end