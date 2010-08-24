# prepare_crossvalidation.rake
desc "recursively set up a matrix for crossvalidation"
task :prepare_crossvalidation, :matrix_id, :stages, :n, :needs => :environment do |t,args|
  args.with_defaults(:matrix_id => 1, :stages => 2, :n => 5)
  
  matrix_id = args[:matrix_id].to_i
  stages    = args[:stages].to_i
  nleaves   = args[:n].to_i

  matrix = Matrix.find(matrix_id)

  raise(ArgumentError, "Matrix id must be a Fixnum, is a #{matrix_id.class}") unless matrix_id.is_a?(Fixnum) || matrix_id.nil?
  raise(ArgumentError, "Matrix #{matrix_id} is a mask and cannot be converted.") if matrix.is_a?(LeafMatrix)
  raise(ArgumentError, "Matrix #{matrix_id} is already a crossvalidation matrix. You must make a copy of it if you wish to prepare it for a different kind of crossvalidation.") if matrix.is_a?(TreeMatrix) && matrix.children.size > 0
  raise(ArgumentError, "You must have at least one stage.") if stages < 1

  # Change matrix type
  say_with_time "Changing matrix #{matrix_id} class to NodeMatrix" do
    Matrix.update_all( "type = 'NodeMatrix'", "id = #{matrix_id} AND type IS NULL" )
  end unless Matrix.is_a?(NodeMatrix)

  # Reload the matrix.
  matrix = NodeMatrix.find(matrix_id)

  if stages > 1
    say_with_time "Creating nodes for matrix #{matrix_id}" do
      nodes = matrix.generate_nodes nleaves
      nodes.each do |node|
        # Recurse
        raise(ArgumentError, "Node not saved") if node.id.nil?
        Rake::Task[ :prepare_crossvalidation ].execute(:matrix_id => node.id, :stages => stages-1, :n => nleaves)
      end
    end
  else
    say_with_time "Creating leaves for matrix #{matrix_id}" do
      leaves = matrix.generate_leaves nleaves
    end
  end

end