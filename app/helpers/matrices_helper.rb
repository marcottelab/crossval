module MatricesHelper

  # The link to run experiments for a matrix.
  def run_link(matrix_or_experiment)
    link_to('Run', {
        :controller => matrix_or_experiment.class.table_name,
        :action     => "run",
        :id         => matrix_or_experiment.id },
      :confirm => 'Are you sure?')
  end

  def view_matrix_path(matrix)
    url_for( :controller => "matrices", :action => "view", :id => matrix.id )
  end

  def source_avatar matrix
    sp = matrix.column_species
    r = false
    r ||= sp.size == 3

    sp = matrix.column_species[0..1].downcase
    image_tag("/images/#{sp}.png", :class => "avatar_#{sp}", :title => "#{matrix.column_species}")
  end

  def source_matrices(exp)
    "<ul class=\"avatars\">#{source_matrices_contents(exp)}</ul>"
  end

  def source_matrices_contents(exp)
    l = exp.source_matrices.collect do |sm|
      sp = sm.column_species.downcase[0..1]
      '<li class="avatar">' + link_to( "&nbsp;", matrix_path(sm), :class => sp) + "</li>"
    end.join("\n")

    if l.nil? || l.size == 0
      None
    else
      l
    end
  end

  # List of matrix children and links to each
  def links_to_matrix_children matrix
    matrix.children.collect { |child| link_to(child.id, child) }.to_sentence
  end

  def fractional_density(matrix)
    if matrix.number_of_rows == 0
      "&#8734;" # infinity (oops)
    else
      "<sup>#{matrix.density}</sup><i>/</i><sub>#{matrix.row_count}</sub>"
    end
  end

  # Display the link to run experiments for a matrix iff it's possible to run for
  # that matrix.
  def run_link_if_appropriate(matrix)
    # Only allow running of parent if its children have been run.
    if matrix.has_experiments_to_run?
      run_link(matrix)
    else
      nil
    end
  end

  def cardinality(matrix)
    if matrix.parent_id.nil?
      nil
    else
      "#{matrix.cardinality+1} / #{matrix.parent.children.count}"
    end
  end

  def experiments_progress_bar(matrix)
    succ = 0
    total = 0
    matrix.experiments.each do |experiment|
      succ +=1 if experiment.has_run_successfully?
      total += 1
    end
    if total > 0
      progress_bar(succ / total.to_f, :denominator => total)
    else
      "None"
    end
  end
end
