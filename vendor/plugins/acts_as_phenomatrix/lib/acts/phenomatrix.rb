require 'activerecord'

module Acts
  module Phenomatrix

    def self.included(base)
      base.extend ClassMethods
    end  

  end
end

ActiveRecord::Base.send(:include, Acts::Phenomatrix)
