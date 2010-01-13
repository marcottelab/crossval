class AddPolymorphismToExperiments < ActiveRecord::Migration
  def self.up
    add_column :experiments, :type, :string, :default => "JohnExperiment"
    change_column :experiments, :type, :string, :default => nil
  end

  def self.down
    remove_column :experiments, :type
  end
end
