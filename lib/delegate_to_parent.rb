module ParentalDelegation
  module ClassMethods
    # This is very similar to delegate from ActiveRecord (it's based on it).
    # It allows us to delegate specific attributes to the parent if one exists.
    # They cannot be assigned, only accessed! Assignment would create a problem
    # as far as saving.
    def delegate_to_parent(*attribs)
      prefix  = nil
      options = attribs.pop
      to      = :parent

      if options.is_a?(Hash)
        to = options[:to] if options.has_key?(:to)

        if options[:prefix] == true && to.to_s =~ /^[^a-z_]/
          raise ArgumentError, "Can only automatically set the delegation prefix when delegating to a method."
        end

        prefix = options[:prefix] && "#{options[:prefix] == true ? to : options[:prefix]}_"
      else
        # Put it back on. Not mandatory for this version of delegate.
        attribs.push options
        options = {}
      end

      file, line = caller.first.split(':', 2)
      line = line.to_i

      attribs.each do |method|
        module_eval(<<-EOS, file, line)
          def #{prefix}#{method}(*args, &block)                    # def customer_name(*args, &block)
            if #{to}_id.nil?                                       #   if parent_id.nil?
              self.attributes['#{method}']                         #     self.attributes['customer_name']
            else                                                   #   else
              #{to}.__send__(:attributes)['#{method}']             #     parent.__send__(:attributes)['customer_name']
            end                                                    #   end
          end                                                      # end
        EOS
      end
    end
  end
end

ActiveRecord::Base.send(:extend, ParentalDelegation::ClassMethods)