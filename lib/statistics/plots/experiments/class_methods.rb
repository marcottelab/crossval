module Statistics
  module Plots
    module Experiments
      module ClassMethods

        attr_reader :experiments

        def initialize experiments
          if experiments.is_a?(Array)
            @experiments = experiments
            @short_titles = nil
          elsif experiments.is_a?(Hash)
            @experiments_by_short_title = experiments
            @short_titles = experiments.invert
            @experiments = experiments.values
          else
            STDERR.puts "Need an array or hash of experiments."
          end
        end


        def results metric
          @results         ||= {}
          @results[metric] ||= begin
            h = {}
            experiments.each do |experiment|
              h[short_title(experiment)] = single_experiment_results(experiment, metric)
            end
            h
          end
        end


        def experiments_by_short_title
          @experiments_by_short_title ||= begin
            h = {}
            experiments.each do |experiment|
              h[short_title(experiment)] = experiment
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
            experiments_by_short_title[a[0]].send(xm) <=> experiments_by_short_title[b[0]].send(xm)
          end
        end

      protected

        def short_title experiment
          if @short_titles.nil?
            "#{experiment.method}.#{experiment.distance_measure}.#{experiment.source_matrix_ids.join('.')}.k#{experiment.k}.mg#{experiment.min_genes}"
          else
            @short_titles[experiment]
          end
        end

        def single_experiment_results experiment, metric
          experiment.results.collect { |r| r.send(metric) }
        end
        
      end
    end
  end
end