#make_experiments.rake
desc "make experiments for a given k"
task :make_experiments, :needs => :environment do |t,arg|
  args = {
    :predict_matrix_id => 178, # 1, # 247,
    :type => 'KnnExperiment',
    :k => 300,
    :methods => ["naivebayes", "average"],
    :distance_measures => KnnExperiment::AVAILABLE_DISTANCE_MEASURES.values,
    :min_idf => 0.0,
    :max_distance => 1.0,
    :min_genes => 4,
    :distance_exponent => 1.0,
    :source_matrix_ids => [1,3,5,7,9,11], #[247,249,251,253,255,257]
  }

  puts "Setting up experiments..."

  attributes = {}
  args.each_pair do |key,value|
    attributes[key] = value unless [:methods, :distance_measures, :source_matrix_ids, :type].include?(key)
  end

  args[:methods].each do |method|
    args[:distance_measures].each do |distance_measure|

      tmp_attributes = attributes
      tmp_attributes[:method] = method
      tmp_attributes[:distance_measure] = distance_measure
      
      experiment = args[:type].classify.constantize.send :new, :attributes => attributes

      experiment.source_matrix_ids = args[:source_matrix_ids]

      STDERR.puts("Experiment: #{experiment.inspect}")

      raise(Error, "type is wrong") unless experiment.type == "KnnExperiment"

      experiment.save!
    end
  end

end
