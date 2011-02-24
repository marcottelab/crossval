def phenotypes
  Phenotype.all.collect { |p| [p.id, p.species, p.long_desc] }
end

def observations matrix_id
  Matrix.find(matrix_id).cells.collect { |cell| [cell.i, cell.j] }
end

def genes matrix_id
  Matrix.find(matrix_id).entries.collect { |entry| entry.i }.sort.uniq
end

# Returns a pair giving the row species and the column species. e.g., for some Arabidopsis matrix used to predict
# Homo sapiens, the species pair would be ['Hs', 'At']. For the matrix being predicted, it would be ['Hs', 'Hs'].
#
# If instead we were trying to predict an Arabidopsis matrix, that would be ['At', 'At'], and matrices used to predict
# it would be like: ['At', 'Hs']
def matrix_species matrix_id
  m = Matrix.find(matrix_id)
  [m.row_species, m.column_species]
end

#dump_data.rake
desc "dump data from a matrix to a file"
task :dump_data, :matrix_id, :write_phenotypes, :needs => :environment do |t,args|
  args.with_defaults(:write_phenotypes => false)

  species = matrix_species(args.matrix_id)

  if args.matrix_id.to_i > 0
    matrix_filename = "genes_phenes.#{args.matrix_id}.#{species.join('-')}.table"
    STDERR.puts "Writing #{matrix_filename}"

    mf = File.new(matrix_filename, 'w')

    observations(args.matrix_id).each do |observation|
      mf.puts observation.join("\t")
    end

    mf.close


    genes_filename = "genes.#{args.matrix_id}.#{species.join('-')}.table"
    STDERR.puts "Writing #{genes_filename}"

    gf = File.new(genes_filename, 'w')

    genes(args.matrix_id).each do |entrez_id|
      gf.puts entrez_id
    end

    gf.close
  end


  if args.write_phenotypes
    STDERR.puts "Writing phenotypes.table"
    phenotypes_filename = "phenotypes.table"
    pf = File.new(phenotypes_filename, 'w')

    phenotypes.each do |phenotype_info|
      pf.puts phenotype_info.join("\t")
    end

    pf.close
  end
  

end