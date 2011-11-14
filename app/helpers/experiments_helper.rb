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
    if experiment.is_a?(KnnExperiment) #|| experiment.is_a?(MartinExperiment)
      return nil if experiment.mean_auroc.nil?
      caption ||= experiment.mean_auroc.to_s
    else
      caption ||= "Distribution"
    end
    link_to caption, matrix_experiment_path(matrix, experiment)
  end

  def select_method form, field, selected = "naivebayes"
    form.select field, Experiment::AVAILABLE_METHODS, :selected => selected
  end

  def select_distance_measure form, field, selected = "hypergeometric"
    form.select field, Experiment::AVAILABLE_DISTANCE_MEASURES, :selected => selected
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

  def knn_experiments(experiments)
    collect_by_type experiments, "KnnExperiment"
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

  def link_to_phenotype result_or_phenotype_id, classifier = nil
    p = nil
    if result_or_phenotype_id.is_a?(Result)
      p = Phenotype.find(result_or_phenotype_id.column)
      classifier ||= result_or_phenotype_id.experiment

    elsif result_or_phenotype_id.is_a?(Phenotype)
      p = result_or_phenotype_id
      classifier ||= @experiment

    else
      p = Phenotype.find(result_or_phenotype_id)
      classifier ||= @experiment
      
    end

    link_to(p.id,
      matrix_phenotype_path(@matrix, p,
        :source_matrix_ids => classifier.source_matrix_ids,
        :classifier => classifier.send(:method),
        :k => classifier.k,
        :dfn => classifier.distance_measure,
        :min_idf => classifier.min_idf || 0,
        :max_distance => classifier.max_distance || 1.0,
        :distance_exponent => classifier.distance_exponent || 1,
        :min_genes => classifier.min_genes || 2
      ), :title => p.long_desc)
  end

  def mini_auc_plot aucs, log = false, mult = 1000

    target = 500
    if log
      aucs.each { |a| a = Math::log(a + 0.00001)*100 }
      target = Math::log(target + 0.00001)*100
    end

    #sparkline_tag(aucs,
    #  :type => 'smooth', :target => target, :height => 100, :step => 0.5,
    #  :has_last => true, :background_color => "#DDD", :line_color => 'black',
    #  :target_color => 'blue') unless aucs.nil? || aucs.size == 0
  end

  def method_avatar method_title
    image_tag "#{method_title}.png", :title => method_title
  end

  def distance_function_avatar distance_function
    image_tag "#{distance_function}.png", :title => distance_function
  end

end
