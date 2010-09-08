class ExperimentsController < MatrixGenericController
  def run
    Workers::FrameWorker.async_run(:experiment_id => params[:id])
    # Inform user.
    flash[:notice] = "Queueing experiment #{params[:id]}"

    find_experiment
    redirect_to matrix_path(@matrix)
  end

  # GET /experiments/1
  # GET /experiments/1.xml
  def show
    find_experiment :include => :results
    if @experiment.is_a?(Integrator)
      find_best_classifiers(@experiment)
      p = Statistics::ExperimentPlot.new(@experiment)
      @flot = p.flot(:area_under_roc)
    else
      if @experiment.child_ids.size > 0
        @flot        = plot_experiment_with_children(@experiment)
      elsif @experiment.has_run_successfully?
        p = Statistics::ExperimentPlot.new(@experiment)
        @flot        = p.flot(:area_under_roc)
      else
        @flot        = plot_experiment_with_children(@experiment)
      end
    end

    respond_to do |format|
      format.html { render_polymorphic_template('show')}# show.html.erb
    end
  end

  # Set up redirects to the proper controllers  
  def edit
    find_experiment
    redirect_to correct_child_url(:edit)
  end

  def new
  end

  def against
    find_experiment
    @comparison = Experiment.find(params[:compare_id])

    @flot = plot_against(@experiment, @comparison)
  end

  def index
    @experiments = Experiment.find(:all, :conditions => {:predict_matrix_id => @matrix_id, :parent_id => nil}, :order => :id)
    #load_rocs 1000 # specifies level of precision for sparkline

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @experiments }
    end
  end

end