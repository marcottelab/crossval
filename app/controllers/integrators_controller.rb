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
    find_experiment
    find_best_classifiers @experiment
    @flot        = plot_experiment(@experiment)

    respond_to do |format|
      format.html { render_polymorphic_template('show', :layout => 'experiments')}# show.html.erb
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

  def update
    @experiment = Integrator.find(params[:id])

    respond_to do |format|
      if !@experiment.run_result.nil? || !@experiment.started_at.nil?
        flash[:notice] = "You can't update an experiment that has been run or is running."
        format.html { redirect_to(@matrix) }
        format.xml  { render :xml => @experiment.errors, :status => :unprocessable_entity }
      elsif @experiment.update_attributes(params[:integrator])
        flash[:notice] = 'Experiment was successfully updated.'
        format.html { redirect_to(@matrix) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @experiment.errors, :status => :unprocessable_entity }
      end
    end

  end

  def create
    @experiment = Integrator.new(params[:integrator])
    @experiment.predict_matrix_id = @matrix_id

    if @experiment.save
      flash[:notice] = "Successfully set up integrator."
      redirect_to url_for(@matrix)
    else
      render :action => 'new'
    end
  end

  def index
    @experiments = Integrator.find(:all, :conditions => {:predict_matrix_id => @matrix_id, :parent_id => nil})

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @experiments }
    end
  end

protected
#  def find_experiment *find_options
#    @experiment_id = params[:id]
#    @experiment = Integrator.find(@experiment_id)
#    raise(ArgumentError, "Integrator does not have predict matrix with this ID") unless @experiment.predict_matrix_id = @matrix_id
#    @klass = @experiment.class
#    @view = "integrators"
#    @experiment
#  end
end