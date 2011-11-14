class Module
  # Use alias_method chaining to swap two methods.
  def swap_methods method_a, method_b, method_c = "method_c_#{(rand*1000000).to_i}"
        module_eval <<-EOV
          alias_method :#{method_c}, :#{method_a}
          alias_method :#{method_a}, :#{method_b}
          alias_method :#{method_b}, :#{method_c}
          undef_method :#{method_c}
        EOV
  end
end
