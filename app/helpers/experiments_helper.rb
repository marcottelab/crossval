module ExperimentsHelper

  def select_parent_experiment form, field, matrix_id
    form.collection_select field, Experiment.find(:all, :conditions => {:parent_id => nil, :predict_matrix_id => matrix_id}, :order => :id), :id, :unique_descriptor
  end

  # Require that all matrices displayed have the appropriate row species
  def select_source_matrix form, field, row_species
    form.collection_select field, Matrix.find(:all, :conditions => {:row_species => row_species}, :order => :id), :id, :unique_descriptor
  end

  def remove_source_link(name, form_builder)
    form_builder.hidden_field(:_delete) + link_to_function(name, "remove_source(this)")
  end

  def add_source_link(name, source, form_builder)
    fields = escape_javascript(new_source_fields(source, form_builder))
    link_to_function(name, h("add_source(this, \"#{source}\", \"#{fields}\")"))
  end

  def new_source_fields(source, form_builder)
    form_builder.fields_for(source.pluralize.to_sym, source.camelize.constantize.new, :child_index => 'NEW_RECORD') do |f|
      render(:partial => "experiments/#{source.underscore}", :locals => { :f => f, :predict_matrix => @matrix })
    end
  end

  def link_to_experiment_if_appropriate(matrix, experiment, caption = nil)
    return nil if experiment.run_result != 0
    if experiment.is_a?(JohnExperiment) || experiment.is_a?(MartinExperiment)
      return nil if experiment.total_auc.nil?
      caption ||= experiment.total_auc.to_s
    else
      caption ||= "Distribution"
    end
    link_to caption, matrix_experiment_path(matrix, experiment)
  end

  def select_method form, field, selected = "naivebayes"
    form.select field, form.object.class::AVAILABLE_METHODS, :selected => selected
  end

  def select_distance_measure form, field, selected = "hypergeometric"
    form.select field, form.object.class::AVAILABLE_DISTANCE_MEASURES, :selected => selected
  end

  def select_validation_type form, field, selected = "row"
    form.select field, ["row", "cell"], :selected => selected
  end

  def integrands(experiment)
    experiment.integrands.collect { |i| i.experiment.title }.join("<br/>")
  end

  def collect_by_type(collection, type)
    collection.reject { |c| c.type != type }
  end

  def integrators(experiments)
    collect_by_type experiments, "Integrator"
  end

  def john_experiments(experiments)
    collect_by_type experiments, "JohnExperiment"
  end

  def john_predictors(experiments)
    collect_by_type experiments, "JohnPredictor"
  end

  def john_distributions(experiments)
    collect_by_type experiments, "JohnDistribution"
  end

  def martin_experiments(experiments)
    collect_by_type experiments, "MartinExperiment"
  end

  def martin_predictors(experiments)
    collect_by_type experiments, "MartinPredictor"
  end

  def martin_distributions(experiments)
    collect_by_type experiments, "MartinDistribution"
  end

  def link_to_experiment_with_when_completed(matrix, experiment)
    return link_to("incomplete", matrix_experiment_path(matrix, experiment)) if experiment.completed_at.nil?
    link_to(distance_of_time_in_words_to_now_ago(experiment.completed_at), matrix_experiment_path(matrix, experiment))
  end

  def subexperiments_progress_bar(experiment)
    succ = 0
    total = 0
    experiment.children.each do |child|
      succ +=1 if child.has_run_successfully?
      total += 1
    end
    if total > 0
      progress_bar(succ / total.to_f, :denominator => total)
    else
      "None"
    end
  end

  def link_to_phenotype roc
    link_to(roc.column,
      matrix_phenotype_path(@matrix, roc.phenotype,
        :source_matrix_ids => @experiment.source_matrix_ids,
        :classifier => @experiment.send(:method),
        :k => @experiment.k,
        :dfn => @experiment.distance_measure,
        :max_distance => @experiment.max_distance || 1.0,
        :min_genes => @experiment.min_genes || 2
      ), :title => roc.phenotype.long_desc)
  end

  def mini_roc_plot sorted_aucs_as_integers, mult = 1000
    sparkline_tag(sorted_aucs_as_integers,
      :type => 'area', :upper => mult/20, :height => 150, :step => 0.5,
      :above_color => "blue", :below_color => "red", :background_color => "#DDD") unless sorted_aucs_as_integers.nil? || sorted_aucs_as_integers.size == 0
  end

  def method_avatar method_title
    image_tag "#{method_title}.png", :title => method_title
  end

  def distance_function_avatar distance_function
    image_tag "#{distance_function}.png", :title => distance_function
  end

end
