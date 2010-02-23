class IntegratorsController < MatrixGenericController
  def run
    Workers::FrameWorker.async_run(:experiment_id => params[:id])
    # Inform user.
    flash[:notice] = "Queueing integrator #{params[:id]}"

    find_experiment params[:id]
    redirect_to url_for(@matrix)
  end

  # GET /experiments/1
  # GET /experiments/1.xml
  def show
    find_experiment params[:id]
    @flot        = plot_experiment(@experiment)

    respond_to do |format|
      format.html { render_polymorphic_template('show')}# show.html.erb
    end
  end


  # GET /experiments/new
  # GET /experiments/new.xml
  def new
    @experiment = Integrator.new(:predict_matrix_id => @matrix_id)
    @experiment.integrands.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @experiment }
    end
  end

  def edit
    @experiment = find_experiment params[:id]
    if @experiment.started_at.nil?
      respond_to do |format|
        format.html # new.html.erb
        format.xml  { render :xml => @experiment }
      end
    else
      flash[:notice] = "Sorry, you can't edit an experiment that has been run or is running."
      redirect_to url_for(@matrix)
    end
  end

  def index
    find_experiment params[:id]
    redirect_to correct_child_url(:index)
  end
end