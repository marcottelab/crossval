class MatrixGenericController < ApplicationController
  before_filter :find_matrix

protected
  def find_experiment id
    @experiment_id = params[:id]
    @experiment = @matrix.experiments.find(id)
    @klass = @experiment.class
    @view = @klass.to_s.tableize
    @experiment
  end

  def find_matrix
    @matrix_id = params[:matrix_id]
    return(redirect_to(matrices_url)) unless @matrix_id
    @matrix = Matrix.find(@matrix_id)
  end

  def render_polymorphic_template action
    render :template => polymorphic_template(action)
  end

  def polymorphic_template action
    "#{@view}/#{action}"
  end
end