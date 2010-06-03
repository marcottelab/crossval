module PhenotypesHelper
  def phenotype_header phenotype
    phenotype.short_desc? ? "Phenotype #{phenotype.id}: #{phenotype.short_desc}" : "Phenotype #{phenotype.id}"
  end
end
