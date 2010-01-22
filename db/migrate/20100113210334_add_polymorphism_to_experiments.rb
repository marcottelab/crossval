class AddPolymorphismToExperiments < ActiveRecord::Migration
  def self.up
    add_column :experiments, :type, :string
  end

  def self.down
    remove_column :experiments, :type
  end
end
