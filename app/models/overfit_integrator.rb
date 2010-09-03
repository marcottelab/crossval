class OverfitIntegrator < Integrator
  def setup_analysis
    self.package_version = "Fastknn #{Fastknn::VERSION}"

    dm = Fastknn.fetch_distance_matrix self.predict_matrix_id, self.source_matrix_ids, (self.min_genes || 2)
    dm.distance_function = self.distance_measure.to_sym
    dm.classifier = self.classifier_parameters
    dm.min_idf = self.min_idf
    dm
  end


  # Find the experiment that best predicts some phenotype
  def best_experiment_id phenotype_id
    best_id = nil
    best_mult = 0.0
    experiment_ids.each do |experiment_id|
      result = Result.find(:all, :conditions => {:column => phenotype_id, :experiment_id => experiment_id})
      mult   = result.roc_area * result.pr_area

      # Keep track of the best ones
      if mult > best_mult
        best_mult = mult
        best_id   = experiment_id
      end
    end

    best_id
  end

  # This crossvalidation function finds the best classifier (from the given options)
  # for each phenotype.
  #
  # Then, it masks the matrix and predicts for each phenotype given the best
  # classifier; it repeats for each mask.
  def crossvalidate
    dm = Fastknn.fetch_distance_matrix self.predict_matrix_id, self.source_matrix_ids, (self.min_genes || 2)
    dm.prepare_filesystem child_row_ids.size

    # Find the best predictor for each phenotype
    best_predictor = {}
    dm.predictable_columns.each do |j|
      best_predictor[j] = best_experiment_id(j)
    end

    # Get the masks
    child_row_ids = dm.child_row_ids
    mask_ids      = child_row_ids.keys.sort
    folder_id     = 0

    mask_ids.each do |mask_id|
      begin
        dm.push_mask child_row_ids[mask_id]

        best_predictor.each_key do |j|
          best_experiment = Experiment.find best_predictor[j]

          # Modify distance matrix so that we're using the correct parameters and
          # distance function.
          dm.distance_function = best_experiment.distance_measure.to_sym
          dm.classifier = best_experiment.classifier_parameters
          dm.min_idf = best_experiment.min_idf

          # Make the prediction (saved to predictions/)
          dm.predict_and_write_column(j, child_row_ids[mask_id])
        end
        # Move predictions to predictions0 or predictions1 or whatever it should be.
        `mv predictions predictions#{folder_id}`
      ensure
        dm.pop_mask
      end
      
      folder_id += 1 # next folder
    end
  end

  def run_analysis
    begin
      self.package_version = "Fastknn #{Fastknn::VERSION}"
      crossvalidate
    rescue ArgumentError
      self.run_result = 1
    rescue => e
      logger.error(e.backtrace.join("\n"))
      self.run_result = 2
    else
      self.run_result = 0
    end
  end
end