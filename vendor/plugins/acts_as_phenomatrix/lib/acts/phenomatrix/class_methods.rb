module Acts
  module Phenomatrix
    module ClassMethods
      # Configuration options are
      #
      # * +entries_table+ - specifies the name of the entries table name (default entries)
      def acts_as_phenomatrix(opts = {})
        has_many :entries, :dependent => :destroy
        has_many :empty_rows, :dependent => :destroy
        has_many :cells, :dependent => :destroy
        include Acts::Phenomatrix::InstanceMethods
      end

      def acts_as_phenomatrix_mask(opts = {})

      end
    end
  end
end