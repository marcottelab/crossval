module Statistics
  module Plots
    class ScatterPlot < Plot
      PLOT_FUNCTION = :r_plot

      def plot_function
        PLOT_FUNCTION
      end

    end
  end
end