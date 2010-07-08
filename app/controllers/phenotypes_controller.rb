class PhenotypesController < MatrixGenericController
  helper :sparklines
  helper_method :params_k, :params_source_matrix_ids, :params_max_distance, :params_min_genes, :params_k, :params_classifier, :params_distance_function
  # GET /phenotypes/1
  # GET /phenotypes/1.xml
  def show
    find_phenotype
    find_genes_by_phenotype
    initialize_globals
    prepare_distance_matrix
    quick_analysis
    quick_predict

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @phenotype }
    end
  end

  def index
    columns = Entry.find(:all, :select => "DISTINCT j", :conditions => {:matrix_id => params_predict_matrix_id}, :joins => :phenotype)
    @phenotypes = columns.collect { |e| e.phenotype }
    count_genes_by_phenotype # Get gene counts to go with each phenotype

    prepare_distance_matrix
    @nearest  = {}
    @nearest1 = {}
    @nearestk = {}

    @phenotypes.each { |p| array_analysis(p.id) }
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @phenotypes }
    end
  end

  def new
    @phenotype = Phenotype.new(:species => @matrix.column_species)

    respond_to do |format|
      format.html
      format.xml { render :xml => @phenotype }
    end
  end

  def edit
    find_phenotype

    if @phenotype.id < 2000000
      flash[:notice] = "Sorry, phenotype is not editable."
      redirect_to matrix_path(@matrix)
    else
      respond_to do |format|
        format.html
        format.xml { render :xml => @phenotype }
      end
    end
  end

  def edit_observations
    find_phenotype
    if @phenotype.id < 2000000
      flash[:notice] = "Sorry, phenotype is not editable."
      redirect_to matrix_path(@matrix)
    else
      respond_to do |format|
        format.html
        format.xml { render :xml => @phenotype }
      end
    end
  end

  def create
    @phenotype = Phenotype.new(params[:phenotype])
    @phenotype.species = @matrix.column_species # Don't let some hacker screw around with the species.

    if @phenotype.save
      flash[:notice] = "Phenotype created."
      redirect_to matrix_phenotype_path(@matrix, @phenotype)
    else
      render :action => 'new'
    end
  end

  def update_observations
    find_phenotype

    respond_to do |format|
      if @phenotype.id < 2000000 && !@matrix.is_a?(TreeMatrix)
        flash[:notice] = "Sorry, phenotype is not editable for this matrix."
        redirect_to matrix_phenotype_path(@matrix, @phenotype)
      elsif @phenotype.update_observations(@matrix, params[:phenotype][:entries])
        flash[:notice] = 'Phenotype updated successfully.'
        format.html { redirect_to matrix_phenotype_path(@matrix, @phenotype) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit_observations" }
        format.xml { render :xml => @phenotype.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    find_phenotype

    respond_to do |format|

      # Prevent some 1337 hacker from changing the hidden field for species, as
      # this could mess up matrix dimensions!
      phenotype_params = params[:phenotype]
      phenotype_params[:species] = @matrix.column_species

      if @phenotype.id < 2000000
        flash[:notice] = "Sorry, phenotype is not editable."
        redirect_to matrix_phenotype_path(@matrix, @phenotype)
      elsif @phenotype.update_attributes(phenotype_params)
        flash[:notice] = 'Phenotype updated successfully.'
        format.html { redirect_to matrix_phenotype_path(@matrix, @phenotype) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml { render :xml => @phenotype.errors, :status => :unprocessable_entity }
      end
    end
  end

protected

  def find_genes_by_phenotype
    @genes = Gene.find(:all, :joins => "INNER JOIN entries e ON (genes.id = e.i)", :conditions => "e.matrix_id = #{@matrix_id.to_i} AND e.j = #{@phenotype_id.to_i}")
  end

  def initialize_globals
    @distance_matrix ||= nil
    @nearestk = nil
  end

  def count_genes_by_phenotype
    entries = Cell.find(:all, :select => "DISTINCT i,j", :conditions => {:matrix_id => params_predict_matrix_id})
    @genes = Hash.new {|h,k| h[k] = 0}
    entries.each do |entry|
      entry.i
      @genes[entry.j] += 1
    end
  end

  def array_analysis phenotype_id
    if @distance_matrix.predict_matrix_has_column?(phenotype_id)
      @nearestk[phenotype_id] = @distance_matrix.knearest(phenotype_id, params[:k].to_i)
    else
      @nearestk[phenotype_id] = []
    end
  end

  def prepare_distance_matrix
    if params.size > 4
      @distance_matrix ||= Fastknn.fetch_distance_matrix params_predict_matrix_id, params_source_matrix_ids, params_min_genes
      @distance_matrix.distance_function = params_distance_function
      @distance_matrix.classifier = params_for_classifier
    else
      @distance_matrix = nil
    end
    @distance_matrix
  end

  def quick_predict
    predictions = @distance_matrix.predict(params[:id].to_i)
    predictions.delete_if { |k,v| v == 0.0 }
    @predictions = Hash.new{ |h,k| h[k] = [] }
    predictions.each_pair do |k,v|
      @predictions[v] << k
    end
    @predictions
  end

  def quick_analysis
    if params.size > 4
      @nearest  = @distance_matrix.nearest params[:id].to_i
      @nearest1 = @distance_matrix.knearest(params[:id].to_i, 1, 1.0) unless params_k == 1
      @nearestk = @distance_matrix.knearest(params[:id].to_i, params_k, params_max_distance || 1.0)
      find_nearest_k_phenotypes
    else
      @nearest = nil
      @nearest1 = nil
      @nearestk = nil
      nil
    end
  end

  def find_nearest_k_phenotypes
    @nearest_k_phenotypes = []
    @nearestk.each do |pk|
      @nearest_k_phenotypes << Phenotype.find(pk[0])
    end
    @nearest_phenotype = @nearest_k_phenotypes.first
  end

  def params_min_genes
    params.has_key?(:min_genes) ? (params[:min_genes] || 2).to_i : nil
  end

  def params_k
    params.has_key?(:k) ? (params[:k] || 1).to_i : nil
  end

  def params_max_distance
    params.has_key?(:max_distance) ? (params[:max_distance] || 1).to_f : nil
  end

  def params_predict_matrix_id
    @matrix_id
  end

  def params_source_matrix_ids
    params.has_key?(:source_matrix_ids) ? params[:source_matrix_ids].collect{|s| s.to_i} : nil
  end

  def params_distance_function
    params.has_key?(:dfn) ? params[:dfn].to_sym : nil
  end

  def params_classifier
    params.has_key?(:classifier) ? params[:classifier].to_sym : :naivebayes
  end

  def params_for_classifier
    if params.has_key?(:classifier)
      return {
        :classifier => params_classifier,
        :k => params_k,
        :max_distance => params_max_distance || 1.0
      }
    else
      return nil
    end
  end

end
