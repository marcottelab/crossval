class MatricesController < ApplicationController

  helper :all

  def run
    @matrix = Matrix.find(params[:id])
    @matrix.experiments.not_started.each do |experiment|
      Workers::FrameWorker.async_run(:experiment_id => experiment.id)
    end

    # Inform user.
    flash[:notice] = "Queueing experiments for matrix id #{params[:id]}"
    redirect_to matrices_url
  end
  
  # GET /rocs/1/show_rocs  
  def show_plot
    @rocs = rocs Matrix.find(params[:id])
  end

  # GET /matrices/1
  # GET /matrices/1.xml
  def show
    @matrix      = Matrix.find(params[:id])
    load_custom_phenotypes unless @matrix.is_a?(TreeMatrix)
    #@row_distribution = row_distribution(@matrix)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @matrix }
    end
  end


  def table
    @matrix     = Matrix.find(params[:id])

    load_experiments

    respond_to do |format|
      format.html
      format.xml { render :xml => @matrix }
    end
  end


  def expand_experiments
    @matrix      = Matrix.find(params[:id], :include => {:experiments => :rocs})
    load_experiments

    load_rocs 1000

    render :update do |page|
      page['experiment_list'].show
      page['experiment_list'].replace_html :partial => 'experiments/list', :locals => { :experiments => @experiments, :rocs => @rocs }, :layout => false
      page['experiment_list_toggle'].replace_html :partial => 'collapse_experiments', :locals => {:id => @matrix.id}
    end
  end

  def collapse_experiments
    render :update do |page|
      page['experiment_list'].hide
      page['experiment_list_toggle'].replace_html :partial => 'expand_experiments', :locals => {:id => params[:id]}
    end
  end

  def view
    @matrix  = Matrix.find(params[:id])
    @cells = @matrix.cells_for_display

    @rows    = Set.new
    @columns = Set.new

    @cells.keys.each do |cell|
      c = cell.split(":")
      @rows    << c[0]
      @columns << c[1]
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @matrix }
    end
  end

  # GET /matrices
  # GET /matrices.xml
  def index
    load_matrices_by_row_species

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @matrices }
    end
  end

  # DELETE /matrices/1
  # DELETE /matrices/1.xml
  def destroy
    @matrix = Matrix.find(params[:id])
    @matrix.destroy

    respond_to do |format|
      format.html { redirect_to(matrices_url) }
      format.xml  { head :ok }
    end
  end

  
  def graph
    @matrix = Matrix.find(params[:id])
    @canvas_id = "experiments_plot"
    plot = Statistics::ExperimentsAreasPlot.new(plot_options)
    @flot = plot.plot(:flot, @canvas_id)
  end

protected

  def load_custom_phenotypes
    @custom_phenotypes = {}
    Phenotype.find(:all, :joins => "inner join matrices on (phenotypes.species = matrices.column_species)", :conditions => ["phenotypes.id > 1000000 AND matrices.id = ?", @matrix.id], :order => :id).each do |phenotype|
      @custom_phenotypes[phenotype.id] = phenotype
    end
  end

  def load_experiments
    @experiments = @matrix.experiments

    @integrators = @matrix.integrators
    @john_experiments = @matrix.john_experiments
    @john_predictors = @matrix.john_predictors
    @john_distributions = @matrix.john_distributions
  end

  def row_distribution matrix
    Flot.new('matrix_row_distribution') do |f|
      #f.yaxis :min => 0, :max => 1
      f.bars
      f.legend :position => "se"
      f.series nil, matrix.row_distribution
    end
  end

  def load_rocs mult
    @aurocs = {}
    @auprcs = {}
    @experiments.each do |experiment|
      @aurocs[experiment.id],@auprcs[experiment.id] = experiment.rocs.spark_areas(mult)
    end
  end

  def load_matrices_by_row_species
    matrices = Matrix.roots_by_row_species
    @source_matrices_by_species = matrices[:source_matrices]
    @predict_matrices_by_species = matrices[:predict_matrices]
  end

  def x_method
    params.has_key?(:x_method) ? params[:x_method].to_sym : :k
  end

  def y_method
    params.has_key?(:y_method) ? params[:y_method].to_sym : :roc_area
  end

  # Generate ExperimentsPlot options from params
  def plot_options
    po = Statistics::ExperimentsPlot.plot_options params
    po[:predict_matrix_id] = @matrix.id
    po
  end
end
