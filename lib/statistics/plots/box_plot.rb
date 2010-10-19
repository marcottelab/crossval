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

    end
  end
end