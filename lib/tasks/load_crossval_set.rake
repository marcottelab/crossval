#dump_data.rake
desc "load crossvalidation set from Martin into a matrix"
task :load_crossval_set, :matrix_id, :filename, :needs => :environment do |t,args|

  raise(ArgumentError, "Need a filename") if args.filename.blank?

  STDERR.puts "Copying matrix #{args.matrix_id}"
  
  template = Matrix.find(args.matrix_id)
  matrix   = template.make_empty_copy
  matrix.save

  f = File.new(args.filename, 'r')

  STDERR.puts "Adding cells"
  while line = f.gets
    line.chomp!
    i,j = line.split

    Cell.find_or_create!(i, j, matrix.id)
  end
end
