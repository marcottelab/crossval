require "rinruby"

class Array
  # Convert to R column
  def to_c
    "c(" + self.join(',') + ")"
  end
end


class Hash
  def to_data_frame name, ignore_empty = true, &block
    max_col_size = 0
    self.values.each do |col|
      max_col_size = col.size if max_col_size < col.size
    end
    STDERR.puts "Max col size = #{max_col_size}"

    tmp = {}
    count = 0

    pairs = block_given? ? self.to_a.sort(&block) : self.to_a
    STDERR.puts "pairs are: #{pairs.inspect}"

    pairs.each do |pair|
      next if pair.second.size == 0 && ignore_empty

      key = pair.first
      col = pair.second

      col += ["NA"]*(max_col_size - col.size)

      if count == 0
        R.eval "#{name} <- data.frame(cbind(\"#{key}\" = #{col.to_c}))"
      else
        R.eval "#{name}$\"#{key}\" = #{col.to_c}"
      end

      count += 1
    end

    name.to_s
  end

  def to_r_params
    params = []
    self.each_pair do |key, value|
      params << "#{key}=#{Statistics::Plots::RParamDictionary.prepare_raw(value)}"
    end

    params.join(", ")
  end
end

module Statistics
  module Plots
    class Plot
      PLOT_D = RParamDictionary.new.
        define_key(:axis_label_orientation, 'las', {:perpendicular => 0, :horizontal => 1, :parallel => 2}).
        define_key(:axis_label_size, 'cex.axis').
        define_key(:title, 'main').
        define_key(:log, 'log', {:false => "", :x => "'x'", :y => "'y'", :xy => "'xy'", :true => "'xy'"}).
        define_key(:x_label, 'xlab').
        define_key(:y_label, 'ylab')


      OPTIONS_D = RParamDictionary.new.
        define_key(:scientific_notation_penalty, 'scipen').
        define_key(:display_digits, 'digits')


      # Check that this isn't duplicating or truncating data based on size of first column.
      def plot_sort results_metric, options = {}, &block
        options = prepare_plot_sort(results_metric, options, &block)
        self.send(plot_function, @data[results_metric], :axis_label_orientation => options[:axis_label_orientation], :axis_label_size => 0.5, :title => options[:title], :log => options[:log])
      end

    protected

      def prepare_plot_sort options
        options.reverse_merge!({
            :inner_margins => [5.1, 4.1, 4.1, 2.1],
            :outer_margins => [0, 0, 0, 0],
            :title => "Untitled",
            :width => 6,
            :height => 7,
            :output => :x11,
            :scientific_notation_penalty => 10, # positive biases toward fixed, negative toward scientific
            :display_digits => 3, # can be 1...22, R default = 7
            :axis_label_orientation => :parallel
          })

        r_set_output options[:output], options[:width], options[:height]
        r_set_margins options[:inner_margins], options[:outer_margins]
        # R.eval "boxplot(#{@data[results_metric]}, main = \"#{options[:title]}\", las=2, cex.axis=0.5)"

        if options[:log] # for log scale, turn off scientific notation by default.
          r_options(:scientific_notation_penalty => options[:scientific_notation_penalty],
            :display_digits => options[:display_digits])
        end

        options
      end

      def r_eval_function fn, data=nil, fn_options = {}
        datastr = data.nil? ? '' : data
        if fn_options.size == 0
          R.eval "#{fn}(#{datastr})"
        else
          datastr = datastr.size > 0 ? "#{datastr}, #{fn_options.to_r_params}" : fn_options.to_r_params
          R.eval "#{fn}(#{datastr})"
        end
      end

      def r_options options = {}
        r_eval_function "options", nil, OPTIONS_D.translate(options)
      end

      def r_boxplot data, options = {}
        options.reverse_merge!({
            :axis_label_orientation => :horizontal, # :horizontal :perpendicular (R:las)
            :axis_label_size => 1
          })

        r_eval_function "boxplot", data, PLOT_D.translate(options)
      end

      def r_plot data, options = {}
        options.reverse_merge!({
            :axis_label_orientation => :parallel, # :horizontal :perpendicular (R:las)
            :axis_label_size => 1
          })
        r_eval_function "plot", data, PLOT_D.translate(options)
      end

      def r_set_output mode, width, height
        if mode == :x11
          R.eval "x11(width=#{width}, height=#{height})"
        else
          mode = "#{mode}.png" unless mode =~ /\.png$/
          path = File.join("plots", mode)
          R.eval "png(\"#{path}\", width=#{width}, height=#{height})"
        end
      end

      def r_set_margins inner, outer
        R.eval "par(mar=#{inner.to_c}, oma=#{outer.to_c})"
      end
    end
  end
end