module PhenotypesHelper
  def phenotype_header phenotype
    phenotype.short_desc? ? "Phenotype #{phenotype.id}: #{phenotype.short_desc}" : "Phenotype #{phenotype.id}"
  end

  def scientific_to_relative hits
    hits.collect do |h|
      -1 * Math.log10(h[1].to_d).to_i
    end
  end

  def plot_hits hits
    sparkline_tag(scientific_to_relative(hits),
      :type => 'discrete', :upper => 1, :above_color => "gray", :below_color => "red")
  end

  def gene_list_item gene_id, id_prefix="g_", known=false
    open_tag  = "<li id=\"#{id_prefix}#{gene_id}\""

    if known
      open_tag += " class=\"known\">"
    else
      open_tag += ">"
    end

    open_tag + gene_id.to_s + "</li>"
  end
end
