def read_crossval_set filename
  f = File.new(filename, "r")

  genes_by_phenotype = Hash.new { |h,k| h[k] = [] }
  while line = f.gets
    line.chomp!
    g,p = line.split.map {|x| x.to_i }
    genes_by_phenotype[p] << g
  end

  f.close
  
  genes_by_phenotype
end


def predict matrix_id, experiment_id

  STDERR.puts "Loading matrix #{matrix_id}"

  experiment   = Experiment.find(experiment_id)
  m            = Fastknn.fetch_distance_matrix matrix_id, experiment.source_matrix_ids, experiment.min_genes
  m.classifier = experiment.classifier_parameters
  compare_to   = Fastknn.fetch_source_matrix matrix_id, experiment.min_genes

  score_bins_for_phenotype = {}


  STDERR.puts "Making predictions and sorting by bin"
  m.predictable_columns.each do |phenotype_id|

    already_known = compare_to.observations(phenotype_id) # get items that were already in the training set for this phenotype.

    score_bins = Hash.new { |h,k| h[k] = [] }

    predictions = m.predict(phenotype_id)

    predictions.keys.each do |gene_id|
      score = predictions[gene_id]
      score_bins[ score ] << gene_id unless already_known.include?(gene_id) # remove items already in training set
      # STDERR.puts "Score for #{gene_id} is #{score}: total size of bin is now: #{score_bins[score].size}" unless score == 0.0
    end

    STDERR.puts "Adding score bin for phenotype #{phenotype_id} of size #{score_bins.size}."
    # STDERR.puts("\t#{score_bins.inspect}") if score_bins.size == 1
    score_bins_for_phenotype[phenotype_id] = score_bins
  end



  score_bins_for_phenotype
end


def gene_ranks score_genes
  rank_by_gene = {}

  rank = 0

  score_genes.keys.sort{ |b,a| a <=> b }.each do |score|
    genes = score_genes[score]
    genes.each do |gene|
      rank_by_gene[gene] = [rank,score]
    end

    rank += 1 unless score_genes[score].size == 0
  end

  rank_by_gene
end


#run_crossval_set.rake
# Run Martin's crossvalidation set (already loaded as a matrix), and write a file with a list of ranks of the test set
# genes (don't include 'known' genes in the ranking).
desc "run crossvalidation set from Martin"
task :run_crossval_set, :matrix_id, :experiment_id, :filename, :needs => :environment do |t,args|

  raise(ArgumentError, "Need a filename containing hidden matrix entries") if args.filename.blank?

  phenotype_score_genes = predict(args.matrix_id.to_i, args.experiment_id.to_i)

  phenotype_ranks = {}
  phenotype_score_genes.keys.each do |pid|
    phenotype_ranks[pid]  = gene_ranks phenotype_score_genes[pid]
    STDERR.puts "For phenotype: #{pid}\tRank size is #{phenotype_ranks[pid].size}"
  end

  hidden                  = read_crossval_set(args.filename) # genes by phenotype


  f = File.new("#{args.filename}.results", "w")

  hidden.each_pair do |pid,genes|
    STDERR.puts "hidden: #{pid}\t#{genes.inspect}"
    if phenotype_ranks.has_key?(pid)
      genes.each do |gene|
        unless phenotype_ranks[pid].has_key?(gene)
          STDERR.puts("Gene #{gene} not found for phenotype #{pid}")
          next
        end

        rank,score = phenotype_ranks[pid][gene]
        f.puts [pid,gene,rank,score].join("\t")
      end

    else
      STDERR.puts("Phenotype not found: #{pid}")
      next
    end
  end
end
