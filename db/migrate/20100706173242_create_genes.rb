class CreateGenes < ActiveRecord::Migration
  def self.up
    create_table :genes do |t|
      t.string :symbol
      t.string :full_name
      t.string :ensembl_id
      t.string :species
      t.text :synonyms
      t.text :summary

      t.timestamps
    end
  end

  def self.down
    drop_table :genes
  end
end
