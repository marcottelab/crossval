module Statistics
  module Plots
    # Plot each classifier/integrator as a box plot on a single graph.
    class ExperimentsScatterPlot < ScatterPlot
      def initialize experiments_by_label
        @experiments = experiments_by_label
      end

      # Check that this isn't duplicating or truncating data based on size of first column.
      def plot metric, options = {}
        options = {
          :axis_label_orientation => :parallel
        }.merge(prepare_plot_sort(options))

        titles_and_experiments = @experiments.to_a

        @data         ||= {}
        @data[metric] ||= results(metric).to_data_frame(metric.to_s) # just store variable name

        self.r_plot @data[metric],
          :axis_label_orientation => options[:axis_label_orientation],
          :axis_label_size => 0.5, :title => options[:title]
      end

      def results metric
        rh = {}
        @experiments.each_pair do |key, exp|
          rh[key] = exp.results.sort_by { |res| res.column }.collect { |res| res.send(metric) }
        end
        rh
      end


    end
  end
end