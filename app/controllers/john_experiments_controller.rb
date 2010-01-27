class JohnExperimentsController < MatrixGenericController
  # GET /experiments/new
  # GET /experiments/new.xml
  def new
    @experiment = JohnExperiment.new(:predict_matrix_id => @matrix_id)
    @experiment.sources.build

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
    @experiment = JohnExperiment.find(params[:id])

    respond_to do |format|
      if !@experiment.run_result.nil? || !@experiment.started_at.nil?
        flash[:notice] = "You can't update an experiment that has been run or is running."
        format.html { redirect_to(@matrix) }
        format.xml  { render :xml => @experiment.errors, :status => :unprocessable_entity }
      elsif @experiment.update_attributes(params[:john_experiment])
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
    @experiment = JohnExperiment.new(params[:john_experiment])
    # ensure_predict_matrix_set(@experiment, @matrix_id)
    
    if @experiment.save
      flash[:notice] = "Successfully set up experiment."
      redirect_to url_for(@matrix)
    else
      render :action => 'new'
    end
  end

end