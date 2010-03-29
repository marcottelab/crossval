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

    # This is very similar to delegate_to_parent, but gives a union instead of
    # simply substituting. In other words, if you have x and x.parent, and you
    # want x to inherit y from x.parent, but also to add its own, this function
    # allows you to do it.
    #
    # The attribute must be an array, not a single value. In this respect, union_with_parent
    # is different from delegate_to_parent, which does not allow an array.
    #
    # I use it on Matrix, with empty_rows. The idea is that if you have a two-
    # stage cross-validation, the intermediate matrix should inherit its parent's
    # empty_rows and also have some of its own.
    #
    # To get that functionality, you'd do something like:
    #  union_with_parent :empty_rows
    def union_with_parent(*attribs)
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
          alias_method :this_#{method.to_sym}, :#{method.to_sym}

          def #{prefix}#{method}(*args, &block)                                               # def customers(*args, &block)
            if #{to}_id.nil?                                                                  #   if parent_id.nil?
              self.__send__ :this_#{method.to_sym}                                            #     self.__send__ :this_customers
            else                                                                              #   else
              #{to}.__send__(:this_#{method.to_sym}) | self.__send__(:this_#{method.to_sym})  #     parent.__send__(:this_customers) | self.__send__(:this_customers)
            end                                                                               #   end
          end                                                                                 # end
        EOS
      end
    end

    # This function resembles union_with_parent, but allows a specific association
    # to mask parent associations. In other words, it gives the set difference of
    # the association in the parent and that of the child -- but only if the child
    # is a leaf.
    def mask_leaf_parent(*attribs)
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
          alias_method :this_#{method.to_sym}, :#{method.to_sym}

          def #{prefix}#{method}(*args, &block)                                               # def customers(*args, &block)
            if #{to}_id.nil? || self.children.size == 0                                       #   if parent_id.nil? || self.children.size == 0
              self.__send__ :this_#{method.to_sym}                                            #     self.__send__ :this_customers
            else                                                                              #   else
              #{to}.__send__(:this_#{method.to_sym}) - self.__send__(:this_#{method.to_sym})  #     parent.__send__(:this_customers) - self.__send__(:this_customers)
            end                                                                               #   end
          end                                                                                 # end
        EOS
      end
    end
  end
end

ActiveRecord::Base.send(:extend, ParentalDelegation::ClassMethods)