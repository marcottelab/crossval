class ExperimentsController < MatrixGenericController
  def run
    Workers::FrameWorker.async_run(:experiment_id => params[:id])
    # Inform user.
    flash[:notice] = "Queueing experiment #{params[:id]}"

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

  # Set up redirects to the proper controllers
  def edit
    find_experiment params[:id]
    redirect_to correct_child_url(:edit)
  end

  def new
    find_experiment params[:id]
    redirect_to correct_child_url(:new)
  end
end