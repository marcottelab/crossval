class CreateIntegrands < ActiveRecord::Migration
  def self.up
    create_table :integrands do |t|
      t.references :integrator, :null => false
      t.references :experiment, :null => false
      t.integer :weightn, :default => 0, :null => false
      t.integer :weightd, :default => 1, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :integrands
  end
end
