class Integrator < Experiment
  has_many :integrands, :foreign_key => :integrator_id, :dependent => :destroy
  has_many :experiments, :through => :integrands

  accepts_nested_attributes_for :integrands, :allow_destroy => true

  # Make sure sources are valid
  validates_associated :integrands

  AVAILABLE_METHODS = {"Default" => "default"}

  # This method has already been aliased to this_sources in Experiment.
  def sources
    s = Set.new
    experiments.each { |experiment| s.merge(experiment.sources) }
    s.to_a
  end

  # This method has already been aliased to this_source_matrices in Experiment.
  def source_matrices
    s = Set.new
    experiments.each { |experiment| s.merge(experiment.source_matrices) }
    s.to_a
  end

  def title
    "Basic integrator (#{id})"
  end

protected

  # Just make sure children have been run successfully (test called before allowing
  # a parent experiment to be run).
  def check_integrands_before_run
    if integrands.count > 0
      integrands(:joins => :experiments).each do |integrand|
        raise(Error, "Integrands must be run first") unless integrand.experiment.has_run_successfully?
      end
    end
  end

  def before_run_internal
    check_integrands_before_run
  end


  # Don't do anything; let
  def prepare_standard_inputs
  end
end