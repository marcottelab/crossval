module Statistics
  module Plots
    
    # Plot each classifier/integrator as a box plot on a single graph.
    class BoxPlot < Plot
      PLOT_FUNCTION = :r_boxplot

      def plot results_metric, options = {}
        plot_sort(results_metric, options) {}
      end

      def plot_function
        PLOT_FUNCTION
      end

      # Function needs to return some kind of hash
      def results(metric);;end

    protected

      def prepare_plot_sort results_metric, options, &block
        options.reverse_merge!({
            :inner_margins => [0.5,1,2,1],
            :outer_margins => [10,2,0.5,1],
            :title => "Classifier Comparison",
            :width => 12,
            :height => 7,
            :output => :x11,
            :log    => false,
            :scientific_notation_penalty => 10, # positive biases toward fixed, negative toward scientific
            :display_digits => 3, # can be 1...22, R default = 7
            :axis_label_orientation => :parallel
          })

        # Get first data frame column
        @data                 ||= {}
        @data[results_metric] ||= results(results_metric).to_data_frame(results_metric.to_s, :ignore_empty, &block) # just store variable name

        r_set_output options[:output], options[:width], options[:height]
        r_set_margins options[:inner_margins], options[:outer_margins]
        # R.eval "boxplot(#{@data[results_metric]}, main = \"#{options[:title]}\", las=2, cex.axis=0.5)"

        if options[:log] # for log scale, turn off scientific notation by default.
          r_options(:scientific_notation_penalty => options[:scientific_notation_penalty],
            :display_digits => options[:display_digits])
        end

        options
      end

    end
  end
end