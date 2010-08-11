module Statistics
  class ExperimentPlot < Plot
    # Load an experiment and its ROCs. If it doesn't have any at the requested threshold, do a temporary read.
    def initialize experiment_or_id
      @experiment = experiment_or_id.is_a?(Fixnum) ? Experiment.find(experiment_or_id) : experiment_or_id
      @rocs       = @experiment.rocs
    end

    # Get the points for drawing a ROC plot.
    def area_under_roc
      ys = @rocs.collect { |r| r.auc }
      xs = Array.new(ys.size) { |r| r / ys.size.to_f }
      xs.zip(ys.sort)
    end

    def precision_recall
      # x: recall, y: precision
      @rocs.collect{ |r| [recall(r), precision(r)] }.sort_by{|r| r[1] }
    end

    def precision roc
      tp = roc.true_positives
      return 0.0 if tp == 0

      tp / (tp + roc.false_positives + 0.0)
    end

    def recall roc
      tp = roc.true_positives
      return 0.0 if tp == 0
      tp / (tp + roc.false_negatives + 0.0)
    end

    def flot plot_function
      raise(ArgumentError, "Need a plot function (:area_under_roc, :precision_recall") unless plot_function.is_a?(Symbol) && [:area_under_roc, :precision_recall].include?(plot_function)

      Flot.new('experiment_roc_plot') do |f|
        #f.yaxis :min => 0, :max => 1
        f.points
        f.legend :position => "se"
        f.yaxis 1
        f.series(@experiment.title, self.send(plot_function), :points => {:show => true, :radius => 1.1})
      end
    end
  end
end

def plot_experiment_with_children experiment
  exp_aucs = experiment.aucs_by_column
  experiment.children.each do |child|
    child.aucs_by_column.each do |column_auc|
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


    roc_lines = experiment.aucs_by_column_with_mean

    f.series "#{experiment.id}: #{experiment.title}", roc_lines.first, :lines => {:show => true}, :points => {:show => false, :radius => 1.1} #sorted_exp_aucs

    if experiment.children.count > 0
      f.series "#{experiment.id}: Average of Children", roc_lines.last, :points => {:show => true, :radius => 1.1}, :lines => {:show => false}
    end
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