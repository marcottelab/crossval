#load_phenotypes.rake
desc "load phenotypes from phenolog-style files"
task :load_phenotypes, :needs => :environment do |t|
  
  FasterTSV.foreach("data/phenotype_descriptions.table", :ignore_header_lines => 1) do |line|
    # Sanitize the SQL and then execute it
    sql = Phenotype.send :sanitize_sql_array, ["INSERT INTO phenotypes (id, long_desc, species) VALUES (?, ?, ?);", line[1], line[2], line[0]]
    ActiveRecord::Base.connection.execute sql
  end
end