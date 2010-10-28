require "rinruby"

# Scatter plot of two experiments' results.
class EScatter
  PATH = File.join(Rails.root, "tmp", "escatter")

  def initialize x_id, y_id, options = { }
    options.reverse_merge!({
        :by     => :roc_area,
        :xlabel => "experiment_#{x_id}",
        :ylabel => "experiment_#{y_id}",
        :title => "Untitled",
        :log   => ''
      })
    FileUtils.mkpath PATH
    write_results :x, x_id, options[:by]
    write_results :y, y_id, options[:by]

    corr = r_plot options[:xlabel], options[:ylabel], options[:by], options[:title], options[:log]
    puts "Pearson correlation is #{corr}"

    # destroy_results
  end

  def r_plot x_label, y_label, by, title, log
    R.eval <<-RCMD
xscatter <- read.csv(file="#{File.join(PATH,results_filename(:x))}",head=TRUE,sep=",",row.names=1)
yscatter <- read.csv(file="#{File.join(PATH,results_filename(:y))}",head=TRUE,sep=",",row.names=1)
scatter  <- data.frame(cbind("#{x_label}"=xscatter$#{by}), row.names=rownames(xscatter))
scatter$"#{y_label}"<- yscatter$#{by}
options(scipen=10,digits=2)
pdf("plots/#{x_label}.#{y_label}.#{by}.scatter.pdf")
plot(scatter$"#{x_label}", scatter$"#{y_label}", xlab="#{x_label}", ylab="#{y_label}", main="#{title}", log='#{log}')
dev.off()
pearsoncor <- cor(scatter$"#{x_label}", scatter$"#{y_label}")
RCMD
    R.pearsoncor # return pearson correlation
  end

  def write_results x_or_y, exp_id, col, order_by = :column
    filename = results_filename x_or_y
    Dir.chdir(PATH) do
      f = File.new(filename, "w")
      f.puts Result.report_table(:all, :select => "results.\"column\", results.#{col}", :conditions => "experiments.id = #{exp_id}", :joins => :experiment, :order => 'results."column"').to_csv
      f.close
    end
    filename
  end

  def results_filename x_or_y
    "#{x_or_y}scatter.csv"
  end

  def destroy_results x_or_y = nil
    if x_or_y.nil?
      [destroy_results(:x), destroy_results(:y)]
    else
      filename = results_filename x_or_y
      Dir.chdir(PATH) do
        FileUtils.rm filename
      end
      filename
    end
  end
end