class CleanupExperimentsTable < ActiveRecord::Migration
  def self.up
    add_column :experiments, :roc_area, :decimal, :after => :run_result
    add_column :experiments, :pr_area, :decimal, :after => :roc_area
    Experiment.update_all("roc_area = total_auc")
    remove_column :experiments, :total_auc
    remove_column :experiments, :validation_type
    remove_column :experiments, :arguments
    add_column :experiments, :min_idf, :decimal, :after => :idf_threshold
    Experiment.update_all("min_idf = idf_threshold")
    remove_column :experiments, :idf_threshold
    Experiment.update_all("max_distance = 1.0", "max_distance IS NULL")
    Experiment.update_all("distance_exponent = 1.0", "distance_exponent IS NULL")
    Experiment.update_all("min_genes = 2", "min_genes IS NULL")
    Experiment.update_all("min_idf = 0", "min_idf IS NULL")
  end

  def self.down
    raise IrreversibleMigration
  end
end
