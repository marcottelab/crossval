class Integrator < Experiment
  has_many :integrands, :foreign_key => :integrator_id
  has_many :experiments, :through => :integrands
end