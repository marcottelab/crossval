#load_matrices.rake
desc "load matrices from phenolog-style files (requires that all rows be in terms of a single species, columns may differ)"
task :load_matrices, :row_species, :randomize, :needs => :environment do |t,args|
  args.with_defaults(:randomize => true)
  
  raise(ArgumentError, "Please specify the row species (e.g., [\"Hs\"] if predicting human).") if args.row_species.nil?

  row_species = args.row_species.speciesize # Make sure it was entered properly, can't trust users.

  puts("Looking in data/#{row_species}...")

  Dir.chdir("data/#{row_species}") do

    species_list = [row_species] # Keep track of species
    row_species_found = false

    Dir["genes_phenes.*"].each do |mfile|
      species = mfile.split(".")[1] # Get the species from the filename

      raise(IOError, "Missing rows file for #{species}: genes.#{species} not found.") unless File.exists?("genes.#{species}")

      next if species == row_species
      species_list << species
    end

    # Now that we've got all of our pairs and confirmed that the files exist, let's get started.
    puts("Loading the following matrices: #{species_list.join(", ")}")
    
    species_list.each do |species|
      
      m = say_with_time "Generating matrix for #{species}" do
        NodeMatrix.create_from_file_pair!("genes.#{species}", "genes_phenes.#{species}",
          :title          => "genes_phenes.#{species}", # This can probably change.
          :column_species => species,
          :row_species    => row_species)
      end
      
      if args.randomize
        say_with_time "Generating random matrix for #{species}" do
          mr = m.copy_and_randomize
          mr.save!
          m.update_attribute(:conjugate_id, mr.id)
        end
      end

    end
  end

  puts "Done!"
end