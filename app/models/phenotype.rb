class Phenotype < ActiveRecord::Base
  has_many :entries, :foreign_key => :i
end
