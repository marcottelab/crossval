class OverfitIntegrator < Integrator

  # Different ways to pick a "best" classifier
  AVAILABLE_METHODS = {"ROC area * P/R area (hypervolume)" => "hypervolume",
    "Precision-Recall Area" => "pr_area",
    "ROC Area" => "roc_area"
  }

  validates_inclusion_of :method, :in => AVAILABLE_METHODS.values, :allow_blank => false

  # Set the integrator's experiments to be all valid ones.
  #
  # Valid is defined here as follows:
  # * Has been setup for two-stage crossvalidation (integrators mostly would not
  #   qualify.
  # * Has the same min_genes setting as self.
  # * Has been run successfully (run result of 0).
  def enable_all_experiments!
    exps = Experiment.find(:all, :conditions => {
        :min_genes => self.min_genes,
        :predict_matrix_id => self.predict_matrix_id,
        :run_result => 0
      })
    exps.delete_if { |x| x.children.count == 0 }
    self.experiment_ids = exps.collect { |x| x.id }
  end

  # Find the experiment that best predicts some phenotype
  def best_classifier phenotype_id
    best = nil
    best_metric = 0.0
    experiments.each do |experiment|
      metrics = []

      #STDERR.puts "Experiment id = #{experiment.id}, phenotype id = #{phenotype_id}"

      metrics = experiment.numeric_results(phenotype_id){ |r| self.send("metric_#{metric}".to_sym, r) }
      next if metrics.size == 0
      representative_metric = metrics.median

      # Keep track of the best ones
      if representative_metric > best_metric
        best_metric = representative_metric
        best        = experiment
      end
    end

    STDERR.puts("Phenotype: #{phenotype_id}\tBest result: #{best.nil? ? 'none' : best.id}\t Metric: #{best_metric || 'none'}")

    best
  end
  
protected
  def metric_hypervolume r
    r.roc_area * r.pr_area
  end

  def metric_pr_area r
    r.pr_area
  end

  def metric_roc_area r
    r.roc_area
  end

  def setup_analysis
    self.package_version = "Fastknn #{Fastknn::VERSION}"

    dm = Fastknn.fetch_distance_matrix self.predict_matrix_id, self.source_matrix_ids, (self.min_genes || 2)
    dm.distance_function = self.distance_measure.to_sym
    dm.classifier = self.classifier_parameters
    dm.min_idf = self.min_idf
    dm
  end


  # This crossvalidation function finds the best classifier (from the given options)
  # for each phenotype.
  #
  # Then, it masks the matrix and predicts for each phenotype given the best
  # classifier; it repeats for each mask.
  def crossvalidate
    dm = Fastknn.fetch_distance_matrix self.predict_matrix_id, self.source_matrix_ids, (self.min_genes || 2)

    # Get the masks
    child_row_ids = dm.child_row_ids
    mask_ids      = child_row_ids.keys.sort
    folder_id     = 0

    # Create folders
    # dm.prepare_filesystem child_row_ids.size
    Dir.chdir(self.root) do

      # Find the best predictor for each phenotype
      best_predictor = {}
      dm.predictable_columns.each do |j|
        best_predictor[j] = best_classifier(j)
      end

      mask_ids.each do |mask_id|
        begin
          dm.push_mask child_row_ids[mask_id]

          best_predictor.each_key do |j|
            best = best_predictor[j]
            next if best.nil? # Some will have no predictions. Skip them.

            # Modify distance matrix so that we're using the correct parameters and
            # distance function.
            dm.distance_function = best.distance_measure.to_sym
            dm.classifier = best.classifier_parameters
            dm.min_idf = best.min_idf

            `mkdir -p predictions`
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

    end # Leave directory.
  end

  def run_analysis
    begin
      self.package_version = "Fastknn #{Fastknn::VERSION}"
      crossvalidate
    rescue ArgumentError => e
      logger.error(e.backtrace.join("\n"))
      update_run_result! 1
    rescue => e
      logger.error(e.backtrace.join("\n"))
      update_run_result! 2
    else
      update_run_result! 0
    end
  end
end