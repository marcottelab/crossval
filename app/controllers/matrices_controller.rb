class MatricesController < ApplicationController

  def run
    @matrix = Matrix.find(params[:id])
    @matrix.experiments.each do |experiment|
      Workers::FrameWorker.async_run(:experiment_id => experiment.id)
    end

    # Inform user.
    flash[:notice] = "Running experiments for matrix id #{params[:id]}"
    redirect_to matrices_url
  end

  # GET /matrices/1
  # GET /matrices/1.xml
  def show
    @matrix    = Matrix.find(params[:id])

    @rocs      = rocs(@matrix)
    # @row_distribution = row_distribution(@matrix)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @matrix }
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

protected
  def rocs matrix
    Flot.new('experiment_roc_plot') do |f|
      #f.yaxis :min => 0, :max => 1
      f.points
      f.legend :position => "se"
      f.yaxis 1
      matrix.experiments.each do |experiment|
        f.series experiment.title, experiment.roc_line
      end
    end
  end

  def row_distribution matrix
    Flot.new('matrix_row_distribution') do |f|
      #f.yaxis :min => 0, :max => 1
      f.bars
      f.legend :position => "se"
      f.series nil, matrix.row_distribution
    end
  end
end
