class CreateMatrices < ActiveRecord::Migration
  def self.up
    create_table :matrices, :force => true do |t|
      # For submatrices
      t.references :parent, :default => nil
      t.integer :cardinality, :default => nil

      # For parent matrices
      t.string  :row_species, :default => "Hs", :limit => 3, :null => false
      t.string  :column_species, :default => "Hs", :limit => 3, :null => false
      t.integer :row_count, :default => 0
      t.integer :column_count, :default => 0
      t.integer :cell_count, :default => 0

      # For all matrices
      t.references :conjugate, :default => nil
      t.string  :title, :null => false, :limit => 300, :unique => true
      t.references :entry_info, :null => false

      t.string :type # polymorphism
      t.timestamps
    end
    add_index :matrices, [:parent_id, :cardinality], :unique => true
    add_index :matrices, :conjugate_id
    add_index :matrices, :row_species
  end

  def self.down
    drop_table :matrices
  end
end
