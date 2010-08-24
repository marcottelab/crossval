class CreateGenes < ActiveRecord::Migration
  def self.up
    create_table :genes do |t|
      t.string :symbol, :limit => 20
      t.string :full_name, :limit => 80
      t.string :ensembl_id, :limit => 20
      t.string :species, :limit => 3
      t.text :synonyms
      t.text :summary

      t.timestamps # updated_at gives the last time the gene was updated from entrez.
    end

    # These could be unique, but let's not push our luck.
    add_index :genes, :symbol
    add_index :genes, :ensembl_id
    add_index :genes, :species

    # Let's populate the table with known Entrez gene IDs
    #say_with_time "Populating genes table from current matrices..." do
    #  entries = Gene.populate_from_matrices
    #end
  end

  def self.down
    drop_table :genes
  end
end
