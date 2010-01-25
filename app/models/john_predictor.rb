class JohnPredictor < JohnExperiment

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

protected
  # In the parent this is used to calculate and load ROCs. Here, we don't want
  # to do anything with it...for now. It'll be overridden again in JohnDistribution.
  def after_run
  end
end
