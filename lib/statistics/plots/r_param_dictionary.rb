module Statistics
  module Plots
    class RParamDictionary
      def initialize *options
        @keys = {}
        @values = Hash.new { |h,k| h[k] = {} }
      end

      def define_key name, translation, values_and_translations = {}
        if @keys.has_key?(name)
          raise(ArgumentError, "Key already exists")
          false
        else
          @keys[name.to_sym] = translation.to_s
          @values[name.to_sym] = values_and_translations
        end
        self
      end

      def define_value key, name, translation
        if @values[key].has_key?(name)
          raise(ArgumentError, "Value already exists")
          false
        else
          @values[name.to_sym] = translation
        end
        self
      end

      # Convert options into string options that resemble the args R takes.
      def translate options
        h = {}
        options.each_pair do |key,val|
          new_key = @keys.has_key?(key) ? @keys[key] : key.to_s
          if @values.has_key?(key)
            h[new_key] = RParamDictionary.prepare_raw(@values[key].has_key?(val) ? @values[key][val] : val)
          else # Not in the dict at all.
            h[new_key] = RParamDictionary.prepare_raw(val)
          end
        end
        h
      end


    protected
      def self.prepare_raw val
        if val.is_a?(Symbol)
          val.to_s
        elsif val.is_a?(Array)
          val.to_c
        elsif val.is_a?(String)
          if val[0...1] =~ /["']/
            val # already quoted
          else
            # Add quotes
            val =~ /[0-9]?[A-Z\s]/ ? "\"#{val}\"" : val
          end
        else
          # appears to already be a string key
          val
        end
      end

    end
  end
end