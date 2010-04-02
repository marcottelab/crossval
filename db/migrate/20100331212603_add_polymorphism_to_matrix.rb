class AddPolymorphismToMatrix < ActiveRecord::Migration
  def self.up
    add_column :matrices, :type, :string
  end

  def self.down
    remove_column :matrices, :type
  end
end
