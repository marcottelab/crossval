class Entry < ActiveRecord::Base
  belongs_to :matrix
  belongs_to :phenotype, :foreign_key => :j
  scope :for_matrix, lambda { |m_id| where(:matrix_id => m_id) }

  def to_s(sep = "\t")
    str  =  self.i.to_s
    str  << sep << self.j.to_s if self.j?
    str
  end

  def write(open_file)
    open_file.puts( self.to_s )
    open_file
  end
end
