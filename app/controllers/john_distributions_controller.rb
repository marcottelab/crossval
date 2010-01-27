class JohnDistributionsController < MatrixGenericController
  # GET /experiments/new
  # GET /experiments/new.xml
  def new
    @experiment = JohnDistribution.new(:predict_matrix_id => @matrix_id)
    @experiment.sources.build

    respond_to do |format|
      format.html { render :template => 'john_experiments/new' } # new.html.erb
      format.xml  { render :xml => @experiment }
    end
  end

  def edit
    @experiment = find_experiment params[:id]
    if @experiment.started_at.nil?
      respond_to do |format|
        format.html { render :template => 'john_experiments/edit' } # new.html.erb
        format.xml  { render :xml => @experiment }
      end
    else
      flash[:notice] = "Sorry, you can't edit an experiment that has been run or is running."
      redirect_to url_for(@matrix)
    end
  end

  def update
    @experiment = JohnDistribution.find(params[:id])

    respond_to do |format|
      if !@experiment.run_result.nil? || !@experiment.started_at.nil?
        flash[:notice] = "You can't update an experiment that has been run or is running."
        format.html { redirect_to(@matrix) }
        format.xml  { render :xml => @experiment.errors, :status => :unprocessable_entity }
      elsif @experiment.update_attributes(params[:john_distribution])
        flash[:notice] = 'Distribution was successfully updated.'
        format.html { redirect_to(@matrix) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @experiment.errors, :status => :unprocessable_entity }
      end
    end
      
  end

  def create
    @experiment = JohnDistribution.new(params[:john_distribution])
    # ensure_predict_matrix_set(@experiment, @matrix_id)
    if @experiment.save
      flash[:notice] = "Successfully set up distribution."
      redirect_to url_for(@matrix)
    else
      render :template => 'john_experiments/new'
    end
  end
end