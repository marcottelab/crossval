require 'Tioga/FigureMaker'


class MyTioga
  include Tioga
  include FigureConstants

  def initialize
    t.save_dir = File.join(Rails.root, "plots").to_s

    t.def_figure("Tradeoff") { tradeoff }
  end

  def t
    @figure_maker ||= FigureMaker.default
  end

  def positions
    @positions ||= Dvector.new
  end

  def tradeoff(options = {})
    options.reverse_merge!({'major_grid' => false, 'minor_grid' => false})

    text_scale   = 0.5
    marker_scale = 0.3
    shift  = text_scale * t.default_text_height_dy * 0.4
    series = Statistics::Plots::Tradeoff.new.find_series

    t.landscape

    t.do_box_labels("Tradeoff between ROC, PR area with increasing {\\it k}", "mean precision-recall area", "mean ROC area")
    t.show_plot(boundaries(series)) do
      series.each_pair do |label,coords|
        t.show_polyline(Dvector.new(coords.collect{|c|c[:x]}), Dvector.new(coords.collect{|c|c[:y]}))
        coords.each do |coord|

          t.show_label 'text' => coord[:k].to_s,
            'x' => coord[:x], 'y' => coord[:y]+shift,
            'justification' => CENTERED,
            'scale' => text_scale,
            'color' => Blue
          t.show_marker('marker' => Bullet, 'point' => [coord[:x], coord[:y]], 'scale' => marker_scale, 'color' => Red)

        end
      end
    end

  end

  def boundaries series_list
    margin = 0.1
    return nil unless series_list.size > 0
    xmin = 1; xmax = 0; ymin = 1; ymax = 0
    series_list.each_value do |coords|
      coords.each do |coord|
        xmin = coord[:x] if coord[:x] < xmin
        xmax = coord[:x] if coord[:x] > xmax
        ymin = coord[:y] if coord[:y] < ymin
        ymax = coord[:y] if coord[:y] > ymax
      end
    end
    width = (xmax == xmin) ? 1 : xmax - xmin
    height = (ymax == ymin) ? 1 : ymax - ymin

    xl = xmin - margin * width; xl = 0 if xl < 0
    xr = xmax + margin * width; xr = 1 if xr > 1
    yb = ymin - margin * height; yb = 0 if yb < 0
    yt = ymax + margin * height; yt = 1 if yt > 1

    [ xl,  xr,  yt,  yb ]
  end

  def do_labels_plot series, &cmd
    t.show_plot()
  end

  def do_label_coord coord, text_scale, marker_scale, color = nil
    shift = text_scale * t.default_text_height_dy * 0.8
    shift = -shift if t.yaxis_reversed
    t.show_label('text' => "k=#{coord[:k]}", 'x' => coord[:x], 'y' => coord[:y]+shift,
      justification => CENTERED, 'scale' => text_scale, 'color' => color)
    t.show_marker('marker' => Bullet, 'point' => [coord[:x], coord[:y]], 'scale' => marker_scale, 'color' => color)
  end

  def labels series, text_scale, marker_scale
    do_labels_plot(series) do
      series.each_pair do |label,coords|
        coords.each do |coord|
          do_label_coord(coord, text_scale, marker_scale)
        end
      end
    end
  end

end


MyTioga.new