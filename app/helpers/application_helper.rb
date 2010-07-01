# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def select_matrix form, field
    form.collection_select field, Matrix.find(:all, :order => :id), :id, :unique_descriptor
  end

  def select_experiment form, field
    form.collection_select field, Experiment.find(:all, :order => :id), :id, :unique_descriptor
  end

  def select_species form, field
    species_list = Matrix.find(:all, :select => "DISTINCT species").collect{ |m| [m.species, m.species] }
    form.select field, species_list
  end

  def remove_nested_link(name, nested_type, form_builder)
    form_builder.hidden_field(:_delete) + link_to_function(name, "remove_nested('#{nested_type.to_s}', this)")
  end

  def add_nested_link(name, nested, nested_type, form_builder)
    fields = escape_javascript(new_nested_fields(nested_type, form_builder))
    link_to_function(name, h("add_nested(this, \"#{nested}\", \"#{fields}\")"))
  end

  def new_nested_fields(source, form_builder)
    form_builder.fields_for(source.pluralize.to_sym, source.camelize.constantize.new, :child_index => 'NEW_RECORD') do |f|
      render(:partial => source.underscore, :locals => { :f => f })
    end
  end

  def distance_of_time_in_words_to_now_ago(datetime)
    return nil if datetime.nil?
    distance_of_time_in_words_to_now(datetime) + " ago"
  end


  # Create a static progress bar to show how many of the calculations have been
  # run.
  def progress_bar(progress, options = {})
    opts = {
      :progress_color => "#10E010",
      :background_color => "white",
      :border_color => "#AAAAAA",
      :width => 100,
      :height => 22,
      :border_width => 2,
      :as => :fraction, # or :percentage
      :denominator => 5
    }.merge options

    text = nil
    if opts[:as] == :fraction
      text = (progress * opts[:denominator]).to_i.to_s + "/#{opts[:denominator]}"
    elsif opts[:as] == :percentage
      text = (progress * 100).to_i.to_s + "%"
    else
      text = progress
    end

    start = progress_bar_open(opts) + progress_bar_inner_open(progress, opts)
    if progress > 0.5
      start + (text || "&nbsp;").to_s + "</span></div>"
    else
      start + "&nbsp;</span><span style=\"float:left;position:absolute;left:#{opts[:width]*progress}px;height:#{opts[:height]}px;width:#{opts[:width]*(1-progress)}px;text-align:center;\">" + (text || "&nbsp;").to_s + "</span></div>"
    end
  end

protected
  def progress_bar_open opts
    "<div style=\"font-size:#{opts[:height]-5}px;position:relative;height:#{opts[:height]}px;width:#{opts[:width]}px;background-color:#{opts[:background_color]};border:#{opts[:border_width]}px solid #{opts[:border_color]}\">"
  end

  def progress_bar_inner_open progress, opts
    "<span style=\"position:absolute;float:left;height:#{opts[:height]}px;width:#{progress*opts[:width]}px;background-color:#{opts[:progress_color]};text-align:center;\">"
  end
end
