class Gene < ActiveRecord::Base

  # True when the gene should probably be updated from Entrez.
  def needs_update? # Every ninety days at most
    self.updated_at == self.created_at || self.symbol.blank? || ((Time.now - self.updated_at) / 86400 > 90)
  end

  # Update the information in this record by scraping it out of an Entrez gene page.
  def update_from_entrez!
    begin
      p = EntrezPage.new(self.id)
      self.update_attributes!(p.to_gene_attributes_h)
    rescue
      Rails.logger.error("Could not access page for Entrez gene id #{self.id}")
    end
  end

  def update_from_entrez
    begin
      p = EntrezPage.new(self.id)
      return self.update_attributes(p.to_gene_attributes_h)
    rescue
      Rails.logger.error("Could not access page for Entrez gene id #{self.id}")
      false
    end
  end

  # Builds genes table just with IDs from the rows already in the matrix.
  def self.populate_from_matrices species
    raise(Error, "Table already populated for species #{species}") if Gene.find(:all, :conditions => {:species => species}).count != 0

    count = 0
    Entry.find(:all, :select => "DISTINCT i, matrices.row_species AS species", :conditions => ["matrices.row_species = ?", species], :joins => "INNER JOIN matrices ON (matrix_id = matrices.id)").each do |row|
      count += 1
      ActiveRecord::Base.connection.execute "INSERT INTO #{self.table_name} ( id, species ) VALUES( #{row.i}, '#{row.species}' );"
    end

    # return the count
    count
  end
end
