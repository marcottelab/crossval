class JohnPredictorsController < MatrixGenericController
  # GET /experiments/new
  # GET /experiments/new.xml
  def new
    @experiment = JohnPredictor.new(:predict_matrix_id => @matrix_id)
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

  def create
    @experiment = JohnPredictor.new(params[:john_experiment])
    # ensure_predict_matrix_set(@experiment, @matrix_id)
    if @experiment.save
      flash[:notice] = "Successfully set up experiment."
      redirect_to url_for(@matrix)
    else
      render :template => 'john_experiments/new'
    end
  end
end