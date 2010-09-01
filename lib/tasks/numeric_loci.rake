# First column should be TAIR loci.
# Second column should be EntrezGene ID.
# Can be obtained from biomart (google it).
# Automatically ignores lines that have no mapping (empty second column).
# Put the file in numeric.mart in data/Sp/ where Sp is At or whatever other
# species you want.
def load_mart filename
  f = File.new(filename, "r")
  t = {} # transform by

  f.gets # ignore header

  while line = f.gets
    line.chomp!
    row = line.split("\t")
    t[row[0]] = row[1] unless row.size == 1 || row[1].size == 0
  end

  t
end

def transform_matrix t, filename
  inf = File.new(filename, "r")
  outf = File.new("#{filename}.out", "w")

  while line = inf.gets
    line.chomp!
    row = line.split("\t")

    if t.has_key?(row[0])
      outf.puts "#{t[row[0]]}\t#{row[1]}"
    else
      STDERR.puts("Could not find transform for #{row[0]} in mart")
    end
  end

  inf.close
  outf.close

  "#{filename}.out"
end


def transform_rows t, filename
  inf = File.new(filename, "r")
  outf = File.new("#{filename}.out", "w")

  while line = inf.gets
    line.chomp!

    if t.has_key?(line)
      outf.puts t[line]
    else
      STDERR.puts("Could not find transform for #{line} in mart")
    end
  end

  inf.close
  outf.close

  "#{filename}.out"
end


#numeric_loci.rake
desc "Attempt to convert non-numeric loci in matrix files to numeric loci via numeric.mart (TAIR locus, EntrezGene ID)"
task :numeric_loci, :row_species, :needs => :environment do |t,args|
  args.with_defaults({:row_species => "At"})

  row_species = args.row_species.speciesize

  puts("Looking in data/#{row_species}...")

  Dir.chdir("data/#{row_species}") do

    t = load_mart("numeric.mart")

    Dir.mkdir("original")

    # Transform the files and then mv them
    Dir["genes*"].each do |file|
      if file =~ /^genes_phenes\.[A-Z][a-z]$/
        transform_matrix t, file

        FileUtils.mv file, "original/"
        `sort #{file}.out |uniq > #{file}`
        `rm #{file}.out`

      elsif file =~ /^genes\.[A-Z][a-z]$/
        transform_rows t, file

        FileUtils.mv file, "original/"
        `sort #{file}.out |uniq > #{file}`
        `rm #{file}.out`
        
      end

    end
  end

  puts "Done!"
end