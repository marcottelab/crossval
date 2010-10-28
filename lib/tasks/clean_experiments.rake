# WARNING: This rake task is broken. It doesn't account properly for experiments
# which are cross-validation children. You can uncomment the matrix cleanup, but
# not the experiment cleanup.

#clean_experiments.rake
desc "remove experiments that no longer exist in the database"
task :clean_experiments, :needs => :environment do |t,args|

  Dir.foreach(File.join("tmp", "work")) do |file|
    next unless file =~ /^matrix\_[0-9]+$/

    Dir.chdir(File.join("tmp", "work")) do

      say_with_time "Checking #{file}" do

        id = file.split('_').last.to_i
        if Matrix.find(id).nil?
          say_with_time "Deleting #{file} which no longer exists in database" do
            rm_rf file
          end
        else

          Dir.foreach(file) do |exp_file|
            next unless exp_file =~ /^experiment\_[0-9]+$/

            Dir.chdir(file) do

              say_with_time "Checking #{exp_file}" do

                exp_id = exp_file.split('_').last.to_i
                exp    = Experiment.find_by_id(exp_id)
                if exp.nil? || exp.predict_matrix_id != id
                  say_with_time "Deleting #{exp_file} which no longer exists in database for #{file}" do
                    # rm_rf exp_file
                  end
                end

              end
            end
          end


        end

      end

    end


  end
end