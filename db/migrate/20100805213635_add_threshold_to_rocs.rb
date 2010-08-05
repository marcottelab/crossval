class AddThresholdToRocs < ActiveRecord::Migration
  def self.up
    add_column :rocs, :threshold, :decimal, :default => 0
    
    remove_index :rocs, [:column,:experiment_id]
    add_index :rocs, [:column,:experiment_id,:threshold], :unique => true
  end

  def self.down
    raise IrreversibleMigration
  end
end
