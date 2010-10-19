module Statistics
  module Plots
    # Plot each classifier/integrator as a box plot on a single graph.
    class ExperimentsBoxPlot < BoxPlot
      METHODS           = ["naivebayes", "average"]
      DISTANCE_MEASURES = KnnExperiment::AVAILABLE_DISTANCE_MEASURES.values

      def initialize conditions = {}, source_matrix_ids = [1,3,5,7,9,11]
        @conditions = conditions.reverse_merge!({
            :predict_matrix_id  => 178,
            :min_genes          => 4,
            :distance_exponent  => 1.0,
            :max_distance       => 1.0,
            :min_idf            => 0.0
          })
        @source_matrix_ids = source_matrix_ids
      end


      def results metric
        @results         ||= {}
        @results[metric] ||= ExperimentsBoxPlot.results(experiments(metric), metric)
      end

      def experiments metric = nil
        @experiments ||= if metric.nil?
          Experiment.find(:all, :conditions => @conditions, :order => "k DESC")
        else
          exp_metric = metric_for_experiments(metric)
          Experiment.find(:all, :conditions => @conditions, :order => "k DESC, #{exp_metric} DESC")
        end
      end

      def experiments_by_short_title
        @experiments_by_short_title ||= begin
          h = {}
          experiments.each do |experiment|
            h[ExperimentsBoxPlot.short_title(experiment)] = experiment
          end
          h
        end
      end

      def metric_for_experiments metric
        metric == :roc_area ? :mean_auroc : :mean_auprc
      end

      def plot results_metric, options = {}
        options.reverse_merge!({:title => "Comparison of Neighborhood Classifiers by ROC Area"})
        xm = metric_for_experiments(results_metric)
        plot_sort(results_metric, options) do |a,b|
          # a[0], b[0]: short title for the results
          # send(xm):   e.g., experiment.mean_auroc
          if experiments_by_short_title[a[0]].nil?
            STDERR.puts "a[0] is nil: #{a[0]}"
          end

          if experiments_by_short_title[b[0]].nil?
            STDERR.puts "b[0] is nil: #{b[0]}"
          end
          
          experiments_by_short_title[a[0]].send(xm) <=> experiments_by_short_title[b[0]].send(xm)
        end
      end

    protected

      def self.short_title experiment
        "#{experiment.method}.#{experiment.distance_measure}.#{experiment.source_matrix_ids.join('.')}.k#{experiment.k}"
      end

      def self.single_experiment_results experiment, metric
        experiment.results.collect { |r| r.send(metric) }
      end

      def self.results experiments, metric
        h = {}
        experiments.each do |experiment|
          h[short_title(experiment)] = single_experiment_results(experiment, metric)
        end
        h
      end
    end
  end
end