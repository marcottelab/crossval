class CreateExperiments < ActiveRecord::Migration
  def self.up
    create_table :experiments, :force => true do |t|
      t.references :predict_matrix, :null => false
      t.string :method, :limit => 200
      t.string :distance_measure, :limit => 200
      t.integer :k
      t.integer :min_genes, :default => 2
      t.float :min_idf, :default => 0.0
      t.float :distance_exponent, :default => 1.0
      t.float :max_distance, :default => 1.0

      # These are only used when experiments/analyses are run.
      t.string :package_version
      t.datetime :started_at
      t.datetime :completed_at
      t.float :mean_auroc
      t.float :mean_auprc
      t.integer :run_result, :default => nil

      t.integer :parent_id # tree
      t.string :type #polymorphism
      t.timestamps
    end
    
    add_index :experiments, :parent_id
    add_index :experiments, :predict_matrix_id
  end

  def self.down
    drop_table :experiments
  end
end
