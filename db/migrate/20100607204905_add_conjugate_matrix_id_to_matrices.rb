class AddConjugateMatrixIdToMatrices < ActiveRecord::Migration
  def self.up
    add_column :matrices, :conjugate_matrix_id, :integer
    add_column :matrices, :cell_count, :integer
    add_index :matrices, :row_species
    add_index :matrices, :conjugate_matrix_id

    # Set cell count
    Matrix.all.each do |matrix|
      matrix.update_attribute(:cell_count, matrix.cells.count)
    end
  end

  def self.down
    remove_column :matrices, :conjugate_matrix_id
    remove_column :matrices, :cell_count
    remove_index :matrices, :row_species
  end
end
