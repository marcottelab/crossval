class ExperimentsController < MatrixGenericController
  def run
    Workers::FrameWorker.async_run(:experiment_id => params[:id])
    # Inform user.
    flash[:notice] = "Queueing experiment #{params[:id]}"

    find_experiment
    redirect_to url_for(@matrix)
  end

  # GET /experiments/1
  # GET /experiments/1.xml
  def show
    find_experiment
    @flot        = plot_experiment_with_children(@experiment)

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
    find_experiment
    redirect_to correct_child_url(:new)
  end

  def against
    find_experiment
    @comparison = Experiment.find(params[:compare_id])

    @flot = plot_against(@experiment, @comparison)
  end

  def index
    @experiments = Experiment.find(:all, :conditions => {:predict_matrix_id => @matrix_id, :parent_id => nil})

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @experiments }
    end
  end
end