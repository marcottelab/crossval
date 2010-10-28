require "rinruby"

# Scatter plot of two experiments' results.
#
# I use this one to show all experiments for matrix 178
# exps = Experiment.find(:all, :conditions => {:min_genes => 4, :predict_matrix_id => 178, :run_result => 0}, :order => 'k ASC, method ASC, distance_measure DESC')
# q = EHeatmap.new(exps)
# q.image "", "Human: All classifiers by ROC area across all diseases"
class EHeatmap
  PATH = File.join(Rails.root, "tmp", "eheatmap")

  def initialize experiments, options = { }
    options.reverse_merge!({
        :by     => :roc_area,
        :title => "Untitled",
      })

    # Convert from IDs to experiments.
    experiments = experiments.collect { |id| Experiment.find(id) } unless experiments.first.is_a?(Experiment)

    experiments.each do |exp|
      write_results exp.id
    end

    r_prepare experiments, options[:by], options[:title]
  end

  def label experiment
    "#{experiment.method}_#{experiment.distance_measure}_k#{experiment.k}_#{experiment.id}"
  end

  def r_prepare experiments, by, title
    experiments.each do |experiment|
      R.eval <<RCMD
exp#{experiment.id} <- read.csv(file="#{File.join(PATH,results_filename(experiment.id))}",head=TRUE,sep=",",row.names=1)
RCMD
    end

    first_exp = experiments.shift

    # Add the first experiment on to a new data frame.
    R.eval <<RCMD
hm <- data.frame(cbind("#{label(first_exp)}"=exp#{first_exp.id}$#{by}), row.names=rownames(exp#{first_exp.id}))
RCMD

    experiments.each do |exp|
      R.eval <<RCMD
hm$#{label(exp)} <- exp#{exp.id}$#{by}
RCMD
    end

    # The R for this came from: http://www.phaget4.org/R/image_matrix.html
    def image filename, title
      R.eval <<RCMD
 dm <- data.matrix(hm)
 min <- min(dm)
 max <- max(dm)
ylabels <- colnames(hm)
xlabels <- rownames(hm)
layout(matrix(data=c(1,2), nrow=1, ncol=2), widths=c(11,1), heights=c(1,1))

# Red and ranges from 0 to 1 while blue ranges from 1 to 0, green is constant
color_ramp <- rgb( seq(0,1,length=256), seq(0,1,length=256), seq(1,0,length=256) )
color_levels <- seq(min, max, length=length(color_ramp))

# Data map
par(mar = c(3,11,2,1))
image(1:length(xlabels), 1:length(ylabels), dm, col=color_ramp, xlab='', ylab='', las=PERPENDICULAR<-2, axes=FALSE, zlim=c(min,max))
title(main="#{title}")

axis(BELOW<-1, at=1:length(xlabels), labels=xlabels, las=VERTICAL<-3, cex.axis=0.5)
axis(LEFT<-2, at=1:length(ylabels), labels=ylabels, las=HORIZONTAL<-1, cex.axis=0.6)

# color scale
par(mar = c(3,1.5,1,1))
image(1, color_levels, matrix(data=color_levels, ncol=length(color_levels), nrow=1), col=color_ramp, xlab='', ylab='', xaxt='n', las=HORIZONTAL<-1)
layout(1)
RCMD
    end

    # Produce a matrix of scatter plots for all of the experiments.
    # Note that log-scale doesn't work.
    def plot filename, title
#pdf('plots/all_by_all.#{filename}.pdf')
# dev.off()
      R.eval <<RCMD
plot(hm, main='#{title}', xlim=c(0.3,1), ylim=c(0.3,1))
RCMD
    end

#    R.eval <<-RCMD
#options(scipen=10,digits=2)
#RCMD
#pdf("plots/heatmap.pdf")
#plot(scatter$"#{x_label}", scatter$"#{y_label}", xlab="#{x_label}", ylab="#{y_label}", main="#{title}", log='#{log}')
#dev.off()
#pearsoncor <- cor(scatter$"#{x_label}", scatter$"#{y_label}")
#RCMD
#    R.pearsoncor # return pearson correlation
  end

  def write_results exp_id, order_by = :column
    filename = results_filename exp_id
    Dir.chdir(PATH) do
      f = File.new(filename, "w")
      f.puts Result.report_table(:all, :select => "results.\"column\", results.roc_area, results.pr_area", :conditions => "experiments.id = #{exp_id}", :joins => :experiment, :order => 'results."column"').to_csv
      f.close
    end
    filename
  end

  def results_filename exp_id
    "results#{exp_id}.csv"
  end

end