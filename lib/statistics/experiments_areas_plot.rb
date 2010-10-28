module Statistics
  # For a set of experiments, plot ROC area against PR area, with series by k
  # setting.
  class ExperimentsAreasPlot < ExperimentsPlot
    # Call this function like you'd call Experiment.find(:all, ...)
    # (Except leave out the :all, which is included automatically.)
    # You need not supply any options. You can also supply options for
    # ExperimentsPlot, such as :series_by.
    def initialize options = {}
      @options    = ExperimentsAreasPlot.default_options(options)
      @matrix     = Matrix.find(@options[:predict_matrix_id])
      @series_long_names = {}
      @series_arr = series
      @series_arr.each do |short_name, series|
        @series_long_names[short_name] = series_long_name(series, x_method, options_for_find)
      end
    end

    # Plot with some plotter (flot or gnuplot) and on some canvas id
    def plot plotter, plot_id = 'experiments_plot'
      if plotter == :flot || plotter == :gnuplot
        self.send plotter, plot_id
      else
        raise ArgumentError, "Unrecognized plotter '#{plotter}'"
      end
    end

    # Plot in Flotomatic.
    def flot plot_id = 'experiments_plot'
      plot_mode = @options[:plot_mode]
      plot_mode_opts = {}
      #plot_mode_opts[:radius] = 2 if plot_mode == :points
      #raise(ArgumentError, "points requested") if plot_mode == :points

      Flot.new(plot_id) do |f|
        f.lines
        f.grid :hoverable => true
        f.legend :container => "##{plot_id}_legend"
        @series_arr.each_pair do |series_id, experiments|
          f.series_for(@series_long_names[series_id], experiments,
            :x => x_method, :y => @options[:y_method], :tooltip => :tooltip,
            :options => {:points => {:show => true}}
          )
        end
      end
    end

    # Plot in GNUplot
    def gnuplot plot_id
      
    end

    def x_method
      @options[:x_method]
    end

  protected

    # Fetch experiments based on @options.
    def experiments *addl_find_options
      exps = @matrix.experiments.by_min_genes(@options[:min_genes]).by_min_idf(@options[:min_idf]).by_max_distance(@options[:max_distance]).by_distance_exponent(@options[:distance_exponent]).by_matrix_id(@options[:predict_matrix_id]).order_by(@options[:order_by]).find(*addl_find_options)
      exps.delete_if { |x| Set.new(x.source_matrix_ids) != Set.new(@options[:source_matrix_ids])} unless @options[:source_matrix_ids] == :any

      # Sort either by the number of source_matrix_ids (integrator) or k
      exps.sort_by {|x| x.respond_to?(:experiment_ids) ? x.experiment_ids.count : x.attributes[@options[:order_by].to_s]}
    end

    # Parse experiments into series of data.
    def series
      attr_combos = ExperimentsAreasPlot.options_for_attributes(@matrix, @options[:series_by])
      s = {}
      attr_combos.each do |series_conditions|
        series_id = series_short_name(series_conditions, options_for_find)
        raise(Error, "Attempted to double-set series") if s.has_key?(series_id)
        s[series_id] = experiments(:all, :conditions => series_conditions, :include => :sources)
      end

      s.delete_if { |k,v| v.size == 0 }

      s
    end

    # Gets only those options on this object that are attributes.
    def options_for_find
      opts = @options.dup
      opts.delete_if { |k,v| [:plot_mode, :series_by, :x_method, :y_method, :order_by].include?(k)}
    end

    def self.default_options options
      #raise(ArgumentError, "min_genes should be symbol") unless options.has_key?(:min_genes) && options[:min_genes] == 4
      options.reverse_merge!({
        :min_genes => 2,
        :min_idf => 0.0,
        :max_distance => 1.0,
        :distance_exponent => 1.0,
        :plot_mode => :lines,
        :series_by => [:method, :distance_measure],
        :predict_matrix_id => 1,
        :x_method => :mean_auroc,
        :y_method => :mean_auprc,
        :order_by => :k
      })

      STDERR.puts options.inspect

      # Ensure that the source matrices are set properly.
      unless options.has_key?(:source_matrix_ids)
        predict_matrix = Matrix.find(options[:predict_matrix_id])
        source_matrices = Matrix.roots_by_row_species[:source_matrices][predict_matrix.row_species]
        source_matrices << predict_matrix
        options[:source_matrix_ids] = source_matrices.collect{|m| m.id}.sort
      end

      options
    end

  end
end