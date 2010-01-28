module ExperimentsHelper

  def remove_source_link(name, form_builder)
    form_builder.hidden_field(:_delete) + link_to_function(name, "remove_source(this)")
  end

  def add_source_link(name, source, form_builder)
    fields = escape_javascript(new_source_fields(source, form_builder))
    link_to_function(name, h("add_source(this, \"#{source}\", \"#{fields}\")"))
  end

  def new_source_fields(source, form_builder)
    form_builder.fields_for(source.pluralize.to_sym, source.camelize.constantize.new, :child_index => 'NEW_RECORD') do |f|
      render(:partial => "experiments/#{source.underscore}", :locals => { :f => f })
    end
  end

  def link_to_experiment_if_appropriate(matrix, experiment)
    return nil if experiment.run_result != 0
    if experiment.is_a?(JohnExperiment) || experiment.is_a?(MartinExperiment)
      return nil if experiment.total_auc.nil?
      link_to experiment.total_auc, matrix_experiment_path(matrix, experiment)
    else
      link_to "Distribution", matrix_experiment_path(matrix, experiment)
    end
  end

  def select_method form, field
    form.select field, form.object.class::AVAILABLE_METHODS
  end

  def select_distance_measure form, field
    form.select field, form.object.class::AVAILABLE_DISTANCE_MEASURES
  end

  def select_validation_type form, field
    form.select field, ["row", "cell"]
  end

 def collect_by_type(collection, type)
    collection.reject { |c| c.type != type }
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
end
