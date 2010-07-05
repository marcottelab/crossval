class MetaController < ApplicationController
  def status
    respond_to do |format|
      format.html # status.html.erb
    end
  end

  def reload
  end

end
