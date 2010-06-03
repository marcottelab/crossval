class PhenotypesController < ApplicationController
  # GET /phenotypes/1
  # GET /phenotypes/1.xml
  def show
    @phenotype      = Phenotype.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @phenotype }
    end
  end

end
