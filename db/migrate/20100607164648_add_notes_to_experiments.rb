class AddNotesToExperiments < ActiveRecord::Migration
  def self.up
    add_column :experiments, :note, :text
    add_column :experiments, :package_version, :string
    add_column :experiments, :max_distance, :decimal
  end

  def self.down
    remove_column :experiments, :note
    remove_column :experiments, :package_version
    remove_column :experiments, :max_distance
  end
end
