class ExperimentActsAsTree < ActiveRecord::Migration
  def self.up
    add_column :experiments, :parent_id, :integer
    add_index :experiments, :parent_id
  end

  def self.down
    remove_column :experiments, :parent_id
  end
end
