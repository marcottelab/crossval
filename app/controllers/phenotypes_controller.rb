class PhenotypesController < MatrixGenericController
  helper :sparklines
  helper_method :params_k
  # GET /phenotypes/1
  # GET /phenotypes/1.xml
  def show
    find_phenotype
    prepare_distance_matrix
    quick_analysis

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

protected
  def find_phenotype
    @phenotype ||= Phenotype.find params[:id]
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
    @distance_matrix ||= Fastknn.fetch_distance_matrix params_predict_matrix_id, params_source_matrix_ids, params_min_genes
    @distance_matrix.distance_function = params_distance_function
    @distance_matrix.classifier = params_for_classifier
    @distance_matrix
  end

  def quick_analysis
    @nearest  = @distance_matrix.nearest params[:id].to_i
    @nearest1 = @distance_matrix.knearest(params[:id].to_i, 1, 1.0) unless params_k == 1
    @nearestk = @distance_matrix.knearest(params[:id].to_i, params_k, params_max_distance || 1.0)
    find_nearest_k_phenotypes
  end

  def find_nearest_k_phenotypes
    @nearest_k_phenotypes = []
    @nearestk.each do |pk|
      @nearest_k_phenotypes << Phenotype.find(pk[0])
    end
    @nearest_phenotype = @nearest_k_phenotypes.first
  end

  def params_min_genes
    (params[:min_genes] || 2).to_i
  end

  def params_k
    (params[:k] || 1).to_i
  end

  def params_max_distance
    (params[:max_distance] || 1).to_f
  end

  def params_predict_matrix_id
    @matrix_id
  end

  def params_source_matrix_ids
    params[:source_matrix_ids].collect{|s| s.to_i}
  end

  def params_distance_function
    params[:dfn].to_sym
  end

  def params_for_classifier
    {
      :classifier => (params[:classifier] || :naivebayes).to_sym,
      :k => params_k,
      :max_distance => params_max_distance || 1.0
    }
  end

end
