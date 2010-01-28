class MatricesController < ApplicationController

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
    #@row_distribution = row_distribution(@matrix)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @matrix }
    end
  end

  def expand_experiments
    @matrix      = Matrix.find(params[:id], :include => {:experiments => :rocs})
    @experiments = @matrix.experiments
    @rocs        = rocs(@matrix)

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
    @matrices = Matrix.find(:all, :order => :id)

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

protected

  def row_distribution matrix
    Flot.new('matrix_row_distribution') do |f|
      #f.yaxis :min => 0, :max => 1
      f.bars
      f.legend :position => "se"
      f.series nil, matrix.row_distribution
    end
  end
end
