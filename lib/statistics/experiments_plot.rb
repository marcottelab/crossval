module Statistics
  # Plot multiple experiments dynamically based on a variety of characteristics.
  class ExperimentsPlot < Plot
    DEFAULT_OPTIONS = {
      :series_by => [:method, :distance_measure],
      :for_sources => [1,3,5,7,9,11], # or :any
      :order_by => :k,
      :find_conditions => {:min_genes => 2},
      :min_idf_less_than => 500.0,
      :max_distance_greater_than => 0.0,
      :plot_mode => :lines,
      :legend_pos => 'se'
    }

    # Convert http params to a plot options hash.
    def self.plot_options params
      options = {}
      options[:series_by] = params[:series_by].collect{|s| s.to_sym} if params.has_key?(:series_by)
      options[:order_by] = params[:order_by].to_sym if params.has_key?(:order_by)
      options[:min_idf_less_than] = params[:min_idf_less_than].to_f if params.has_key?(:min_idf_less_than)
      options[:max_distance_greater_than] = params[:max_distance_greater_than].to_f if params.has_key?(:max_distance_greater_than)
      options[:find_conditions][:min_genes] = params[:find_conditions][:min_genes].to_i if params.has_key?(:find_conditions) && params[:find_conditions].has_key?(:min_genes)
      options[:plot_mode] = params[:plot_mode].to_sym if params.has_key?(:plot_mode)
      options[:legend_pos] = params[:legend_pos].to_sym if params.has_key?(:legend_pos)

      if params.has_key?(:for_sources)
        if params[:for_sources].is_a?(Array)
          options[:for_sources] = params[:for_sources].collect{ |s| s.to_i}
        else
          options[:for_sources] = params[:for_sources].to_sym
          options[:plot_mode] ||= :points if options[:for_sources] == :any
        end
      end
      
      # STDERR.puts "Options series_by size is #{options[:series_by].size}"
      options
    end


    NON_MODEL_FIELDS = [
      :created_at,
      :updated_at,
      :started_at,
      :completed_at,
      :id,
      :pr_area,
      :roc_area,
      :package_version,
      :run_result,
      :predict_matrix_id, :type,
      :note,
      :parent_id ]

    FIELD_DEFAULTS    = {
      :min_genes => 2,
      :max_distance => 1.0,
      :min_idf => 0.0,
      :distance_exponent => 1.0
    }

    def initialize matrix, x_method, options = {}
      options.reverse_merge! ExperimentsPlot::DEFAULT_OPTIONS
      options[:find_conditions][:min_genes] = options[:min_genes] if options.has_key?(:min_genes)
      @plot_mode = options.has_key?(:plot_mode) ? options[:plot_mode] : :points
      @legend = {}
      @legend[:position] = options.has_key?(:legend_pos) ? options[:legend_pos] : 'sw'
      raise(ArgumentError, "x method must be a symbol") unless x_method.is_a?(Symbol)
      raise(ArgumentError, "series_by must give a list of symbols") unless options[:series_by].is_a?(Array) && contains_only_symbols?(options[:series_by])

      @x_method = x_method

      attribute_combinations = options_for_attributes(matrix, options[:series_by], options[:find_conditions])
      @series = {}
      @series_long_names = {}
      attribute_combinations.each do |combo|
        find_conditions = options[:find_conditions].merge combo
        name = series_short_name(combo, find_conditions)
        @series[name] = matrix.experiments.find(:all, :conditions => find_conditions, :include => :sources, :order => options[:order_by])

        # Delete outlier series.
        @series[name].delete_if do |exp|
          exp.min_idf >= options[:min_idf_less_than] ||
          exp.max_distance <= options[:max_distance_greater_than] ||
          #!same_sources?(exp, options[:for_sources]) ||
          exp.min_genes != options[:find_conditions][:min_genes]
        end
      end

      @series.delete_if {|name, exp_list| exp_list.size == 0}

      @series.each do |short_name, one_series|
        @series_long_names[short_name] = series_long_name(one_series, x_method, options[:find_conditions])
      end

      raise(ArgumentError, "No series!") unless @series.size > 0
    end


    def flot y_method = :roc_area, plot_id = 'experiments_plot'
      raise(ArgumentError, "y method must be a symbol, and plot id must be a string") unless y_method.is_a?(Symbol) && plot_id.is_a?(String)

      Flot.new(plot_id) do |f|
        f.send @plot_mode
        f.grid :hoverable => true
        f.legend :position => @legend[:position]
        @series.each_pair do |series_id, experiments|
          f.series_for(@series_long_names[series_id], experiments, :x => @x_method, :y => y_method, :tooltip => :tooltip, :options => {:points => {:show => true}})
        end
      end
    end

    def gnuplot x_method, y_method
      # require "gnuplot"
      
      Gnuplot.open do |gp|
        Gnuplot::Plot.new(gp) do |plot|
          plot.title title(x_method,y_method)
          plot.ylabel y_method.to_s.titleize
          plot.xlabel x_method.to_s.titleize

          plot.data << Gnuplot::DataSet.new([@experiments.collect{|exp| exp.send(:x_method)}, @experiments.collect{|exp| exp.send(:y_method)}]) do |ds|
            ds.with = @plot_mode.to_s
            ds.notitle
          end
        end
      end

      nil
    end

    # Generate a tooltip for some experiment
    def self.experiment_tooltip experiment
      delete_pairs = ExperimentsPlot::FIELD_DEFAULTS
      attributes = experiment.attributes
      attributes.delete_if do |key, value|
        key_sym = key.to_sym
        NON_MODEL_FIELDS.include?(key_sym) || (delete_pairs.has_key?(key_sym) && delete_pairs[key_sym] == value)
      end
      clean_attribs = []
      attributes.each_pair do |key, value|
        clean_attribs << ExperimentsPlot::clean_attribute(key, value)
      end
      clean_attribs << ExperimentsPlot::clean_attribute("from", experiment.source_matrix_ids.sort)
      clean_attribs.join(", ") + " (id #{experiment.id})"
    end


  protected
    def self.clean_attribute attr, value
      str = attr + "="
      case attr
      when "k"
        str + value.to_i.to_s
      when "from"
        str + value.join(",")
      when "min_idf"
        str + value.to_f.to_s
      when "distance_measure"
        value.to_sym.to_s
      when "method"
        value.to_sym.to_s
      when "max_distance"
        "Dmax=" + value.to_f.to_s
      when "distance_exponent"
        "Dexp=" + value.to_f.to_s
      when "min_genes"
        "gmin=" + value.to_i.to_s
      else
        "#{attr.to_sym.to_s}: "
      end
    end

    # This function tries to find a name for a series that accurately describes
    # its content based on what the experiments within the series have in common.
    def series_long_name experiments, x_method, find_conditions
      attribs = experiments.first.attributes

      # Remove certain obvious non-result-related fields.
      ignore_attribs =  ExperimentsPlot::NON_MODEL_FIELDS.concat(find_conditions.keys.collect{|k| k.to_s})
      ignore_attribs << x_method
      attribs.delete_if do |key, value|
        ignore_attribs.include?(key.to_sym) || ExperimentsPlot::FIELD_DEFAULTS[key.to_sym] == value
      end

      # Remove anything that is not constant across all experiments in this series.
      experiments.each do |experiment|
        attribs.delete_if do |key, value|
          experiment.attributes[key] != value
        end
      end

      # Now clean up the output.
      clean_attribs = []
      attribs.each_pair do |attr, value|
        clean_attribs << ExperimentsPlot::clean_attribute(attr, value)
      end
      clean_attribs.join(", ")
    end


    def series_short_name attribute_combo, find_conditions
      str = ""
      if attribute_combo.size > 0
        str += attribute_combo.values.join(", ")
        return str if find_conditions.size == 0
      end

      str + ": " + find_conditions.to_s
    end

    def title x_method, y_method
      "#{y_method.to_s} by #{x_method.to_s}"
    end

    def same_sources? exp, sources_opt
      if sources_opt.is_a?(Symbol)
        return true if sources_opt == :any
        raise(ArgumentError, "Unrecognized option for :for_sources, which should be :any or an array of Fixnums")
      elsif sources_opt.is_a?(Array)
        Set.new(sources_opt) == Set.new(exp.source_matrix_ids)
      else
        raise(ArgumentError, ":for_sources must be :any or an array of Fixnums")
      end
    end

    def contains_only_symbols? arr
      arr.each do |item|
        return false unless item.is_a?(Symbol)
      end
      true
    end

    def options_for_attributes matrix, attr_array, find_conditions = {}
      select = "DISTINCT #{attr_array.collect{|a| a.to_s}.join(", ")}"
      STDERR.puts "select is #{select}"
      combos = matrix.experiments.find(:all, :select => select, :conditions => find_conditions).collect do |exp|
        exp.attributes.delete_if{|attr,value| value.nil? }
      end
      combos.delete_if{|combo| combo.size < attr_array.size}

      combos
    end
  end
end