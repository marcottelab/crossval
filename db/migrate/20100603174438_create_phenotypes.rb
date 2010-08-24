class CreatePhenotypes < ActiveRecord::Migration
  def self.up
    create_table :phenotypes do |t|
      t.string :short_desc
      t.text :long_desc, :null => false
      t.string :species, :limit => 3, :null => false

      t.timestamps
    end

    add_index :phenotypes, :species
  end

  def self.down
    drop_table :phenotypes
  end
end
