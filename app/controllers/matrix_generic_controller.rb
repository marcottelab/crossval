class MatrixGenericController < ApplicationController
  before_filter :find_matrix

protected
  def find_experiment *find_options
    @experiment_id = params[:id].to_i
    @experiment = @matrix.experiments.find(@experiment_id, *find_options)
    @klass = @experiment.class
    @view = @klass.to_s.tableize
    @experiment
  end

  def find_phenotype *find_options
    STDERR.puts("find_phenotype called")
    @phenotype_id = params[:id].to_i
    STDERR.puts("phenotype_id = #{@phenotype_id}, matrix = #{@matrix.id}")
    @phenotype    = Phenotype.find(@phenotype_id, *find_options)
    @klass        = @phenotype.class
    @view         = @klass.to_s.tableize
    STDERR.puts("phenotype is #{@phenotype.nil? ? "nil" : @phenotype.to_s }")
    @phenotype
  end

  def find_matrix
    @matrix_id = params[:matrix_id].to_i
    return(redirect_to(matrices_url)) unless @matrix_id
    @matrix = Matrix.find(@matrix_id)
  end

  def render_polymorphic_template action
    render :template => polymorphic_template(action)
  end

  def polymorphic_template action
    "#{@view}/#{action}"
  end
  
  def ensure_predict_matrix_set experiment, matrix_id
    experiment.predict_matrix_id = matrix_id if experiment.predict_matrix_id.nil?
  end

  def correct_child_url_function action
    "#{action.to_s}_matrix_#{view_for_action(action)}_url".to_sym
  end

  def view_for_action action
    action.to_sym == :index ? @view : @view.singularize
  end

  def correct_child_url action
    fn = correct_child_url_function(action)
    send fn, @matrix, @experiment.ancestor_or_self
  end
end
