module Workers
  # This is the worker that is responsible for running asnynchronous analysis jobs.
  class FrameWorker < Workling::Base
    def run options = {}
      # Make sure all input directories are ready.
      # Matrix.prepare_inputs

      opts = options

      experiment = Experiment.find(opts[:experiment_id])

      raise(ArgumentError, "Experiment ID not found") if experiment.nil?

      experiment.prepare_inputs

      unless options.has_key?(:force_parent) && options[:force_parent]
        if experiment.has_run_successfully?
          raise(ArgumentError, "Experiment #{opts[:experiment_id]} has already been run")
        elsif !experiment.has_run_successfully?
          experiment.started_at = nil
          experiment.completed_at = nil
          experiment.run_result = nil
          experiment.reset_for_new_run!
        end
      end

      if experiment.children_have_been_run_successfully?
        logger.info("Running experiment on id #{opts[:experiment_id]}")

        experiment.run

        logger.info("DONE running experiment on id #{opts[:experiment_id]}")
      else
        logger.error("Unable to run experiment: children not run successfully.")
      end
    end
  end
end