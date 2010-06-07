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
    hits.each do |h|
      puts "Hit1 is #{h[1]}"
    end
    sparkline_tag(scientific_to_relative(hits),
      :type => 'discrete', :upper => 1, :above_color => "gray", :below_color => "red")
  end
end
