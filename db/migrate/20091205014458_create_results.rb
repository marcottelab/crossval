class CreateResults < ActiveRecord::Migration
  def self.up

    # Has been modified by a later migration: 20100805213635_add_threshold_to_rocs.rb
    create_table :results do |t|
      t.references :experiment, :null => false
      t.integer :column, :null => false
      t.float :roc_area, :null => false
      t.float :pr_area, :null => false
      t.integer :gene_count, :default => 0
    end

    # index no longer exists; now includes threshold in third position (still unique)
    add_index :results, [:column,:experiment_id], :unique => true
  end

  def self.down
    drop_table :results
  end
end
