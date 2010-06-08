class AddConjugateMatrixIdToMatrices < ActiveRecord::Migration
  def self.up
    add_column :matrices, :conjugate_matrix_id, :integer
    add_index :matrices, :row_species
    add_index :matrices, :conjugate_matrix_id
  end

  def self.down
    remove_column :matrices, :conjugate_matrix_id
    remove_index :matrices, :row_species
  end
end
