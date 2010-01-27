class RocsController < ApplicationController
  # GET /Rocs
  # GET /Rocs.xml
  def index
    @rocs = Roc.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @rocs }
    end
  end

  # GET /Rocs/1
  # GET /Rocs/1.xml
  def show
    @roc = Roc.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @roc }
    end
  end

  # GET /Rocs/new
  # GET /Rocs/new.xml
  def new
    @roc = Roc.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @roc }
    end
  end

  # GET /Rocs/1/edit
  def edit
    @roc = Roc.find(params[:id])
  end

  # POST /Rocs
  # POST /Rocs.xml
  def create
    @roc = Roc.new(params[:Roc])

    respond_to do |format|
      if @roc.save
        flash[:notice] = 'Roc was successfully created.'
        format.html { redirect_to(@roc) }
        format.xml  { render :xml => @roc, :status => :created, :location => @roc }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @roc.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /Rocs/1
  # PUT /Rocs/1.xml
  def update
    @roc = Roc.find(params[:id])

    respond_to do |format|
      if @roc.update_attributes(params[:Roc])
        flash[:notice] = 'Roc was successfully updated.'
        format.html { redirect_to(@roc) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @roc.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /Rocs/1
  # DELETE /Rocs/1.xml
  def destroy
    @roc = Roc.find(params[:id])
    @roc.destroy

    respond_to do |format|
      format.html { redirect_to(Rocs_url) }
      format.xml  { head :ok }
    end
  end
end
