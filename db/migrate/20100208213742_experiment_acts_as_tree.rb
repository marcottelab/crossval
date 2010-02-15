class ExperimentActsAsTree < ActiveRecord::Migration
  def self.up
    # Allow Experiments to have parents
    add_column :experiments, :parent_id, :integer
    add_index :experiments, :parent_id

    
    # Experiments with parents should inherit most of these attributes from their
    # parents, which is done using delegate_to_parent :method, :distance_measure,
    # etc.
    #
    # As such, we want to not require them any longer, and remove default values. These can
    # be set within Rails instead.
    change_column :experiments, :method, :string, :limit => 200, :default => nil
    change_column :experiments, :distance_measure, :string, :limit => 200, :default => nil
    change_column :experiments, :validation_type, :string, :limit => 4, :default => nil
    change_column :experiments, :k, :integer, :default => nil
  end

  def self.down
    remove_column :experiments, :parent_id

    # This is not a truly irreversible migration, since we're not making any
    # significant changes to the columns. However, we want people to think twice
    # about trying to db:migrate:down here.
    #raise IrreversibleMigration, "Reversing this migration does not guarantee the schema will be exactly the same."
  end
end
