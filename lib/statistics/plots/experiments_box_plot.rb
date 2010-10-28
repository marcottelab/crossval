module Statistics
  module Plots
    # Plot each classifier/integrator as a box plot on a single graph.
    class ExperimentsBoxPlot < BoxPlot
      include Statistics::Plots::Experiments::ClassMethods
    end
  end
end