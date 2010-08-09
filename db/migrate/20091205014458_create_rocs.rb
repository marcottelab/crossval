class CreateRocs < ActiveRecord::Migration
  def self.up

    # Has been modified by a later migration: 20100805213635_add_threshold_to_rocs.rb
    create_table :rocs do |t|
      t.references :experiment, :null => false
      t.integer :column, :null => false
      t.decimal :auc, :null => false
      t.integer :true_positives, :null => false
      t.integer :false_positives, :null => false
      t.integer :true_negatives, :null => false
      t.integer :false_negatives, :null => false
      # t.decimal :threshold, :default => 0.0 # added later.
    end

    # index no longer exists; now includes threshold in third position (still unique)
    add_index :rocs, [:column,:experiment_id], :unique => true
  end

  def self.down
    drop_table :rocs
  end
end
