class KnnExperimentsController < MatrixGenericController
  # GET /experiments/new
  # GET /experiments/new.xml
  def new
    @experiment = KnnExperiment.new(:predict_matrix_id => @matrix_id)
    @experiment.sources.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @experiment }
    end
  end

  def edit
    @experiment = find_experiment
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
    @experiment = KnnExperiment.find(params[:id])

    respond_to do |format|
      if !@experiment.run_result.nil? || !@experiment.started_at.nil?
        flash[:notice] = "You can't update an experiment that has been run or is running."
        format.html { redirect_to(@matrix) }
        format.xml  { render :xml => @experiment.errors, :status => :unprocessable_entity }
      elsif @experiment.update_attributes(params[:knn_experiment])
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
    @experiment = KnnExperiment.new(params[:knn_experiment])
    # ensure_predict_matrix_set(@experiment, @matrix_id)
    
    if @experiment.save
      flash[:notice] = "Successfully set up experiment."
      redirect_to matrix_experiment_path(@matrix, @experiment)
    else
      render :action => 'new'
    end
  end

  def against
    @experiment = KnnExperiment.find(params[:id])
    @comparison = Experiment.find(params[:compare_id])

    @flot = plot_against(@experiment, @comparison)
  end

end