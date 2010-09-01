# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

protected
  def rocs matrix_or_experiment
    Flot.new('experiment_roc_plot') do |f|
      #f.yaxis :min => 0, :max => 1
      f.lines
      f.grid :hoverable => true
      f.legend :position => "se", :show => false
      f.yaxis 1
      f.selection :mode => "xy"

      if matrix_or_experiment.is_a?(Matrix)
        # Show all experiments for this matrix
        matrix_or_experiment.experiments.each do |experiment|
          f.series "#{experiment.id}: #{experiment.title}", experiment.roc_line
        end
      elsif matrix_or_experiment.is_a?(Experiment)
        # Just show the experiment
        f.series matrix_or_experiment.title, matrix_or_experiment.roc_line
      elsif matrix_or_experiment.is_a?(Array)
        # Array of experiments passed in
        matrix_or_experiment.each do |experiment|
          f.series "#{experiment.id}: #{experiment.title}", experiment.roc_line
        end
      elsif matrix_or_experiment.is_a?(RocGroup)
        # RocGroup object passed in
        matrix_or_experiment.roc_group_items.each do |item|
          f.series "#{item.experiment.id}: #{item.experiment.title}", item.experiment.roc_line
        end
      end
    end
  end

  def plot_experiment_with_children experiment
    exp_aucs = experiment.roc_areas_by_column
    experiment.children.each do |child|
      child.roc_areas_by_column.each do |column_auc|
        exp_aucs
      end
    end

    Flot.new('experiment_roc_plot') do |f|
      f.points
      f.lines
      f.grid :hoverable => true
      f.legend :position => "se", :show => false
      f.yaxis 1
      f.selection :mode => "xy"


      roc_lines = experiment.roc_areas_by_column_with_mean

      f.series "#{experiment.id}: #{experiment.title}", roc_lines.first, :lines => {:show => true}, :points => {:show => false, :radius => 1.1} #sorted_exp_aucs

      if experiment.children.count > 0
        f.series "#{experiment.id}: Average of Children", roc_lines.last, :points => {:show => true, :radius => 1.1}, :lines => {:show => false}
      end
    end
  end

  # Used by ExperimentsController and JohnExperimentsController
  def plot_experiment experiment
    Flot.new('experiment_roc_plot') do |f|
      #f.yaxis :min => 0, :max => 1
      f.points
      f.legend :position => "se"
      f.yaxis 1
      f.series experiment.title, experiment.roc_line, :points => {:show => true, :radius => 1.1}
    end
  end

  # Plot one experiment against the other
  def plot_against e1, e2
    Flot.new('experiment_roc_plot') do |f|
      f.points
      f.grid :hoverable => true
      f.legend :position => "se"
      f.yaxis 1
      f.series "#{e1.title} against #{e2.title}", e1.aucs_against(e2), :points => {:show => true, :radius => 1.5}
    end
  end
end
