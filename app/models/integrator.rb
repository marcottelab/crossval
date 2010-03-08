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

  def argument_string
    "-m #{method} -s #{self.source_species_to_s}"
  end

  def title
    "Need a title! (#{id})"
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

  # Generates row and column files, makes sure they're in the right directory.
  # Only call from within prepare_inputs_internal, as this guarantees we're in
  # the correct directory and such.
  def prepare_standard_inputs
    # Don't need this for integrator -- inputs have to come from experiment outputs.
    # cell_files = self.copy_source_matrix_inputs

    # Do we need these? Probably need row file, not sure about column file.
    #self.generate_row_file(cell_files)
    #self.generate_column_file

    # Almost certainly need these, for cross-validation:
    # Only copy the predict matrix cells file if it didn't come from one of the
    # source matrices.
    #unless cell_files.include?(self.predict_matrix.cell_file_path)
    FileUtils.cp(self.predict_matrix.cell_file_path, self.root)
    #end
  end

  def prepare_inputs
    prepare_inputs_internal do

      prepare_standard_inputs

      # No need for test sets.
      # self.copy_testsets
    end
  end
end