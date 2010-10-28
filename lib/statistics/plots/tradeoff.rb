module Statistics
  module Plots
    # Shows tradeoff between ROC area and P/R area, with series drawn in order
    # of increasing k values.
    class Tradeoff
      METHODS           = ["naivebayes", "average"]
      DISTANCE_MEASURES = KnnExperiment::AVAILABLE_DISTANCE_MEASURES.values

      def initialize conditions = {}, source_matrix_ids = [1,3,5,7,9,11]
        @conditions = conditions.reverse_merge!({
            :predict_matrix_id  => 178,
            :min_genes          => 4,
            :distance_exponent  => 1.0,
            :max_distance       => 1.0,
            :min_idf            => 0.0
          })
        @source_matrix_ids = source_matrix_ids
      end

      
      def find_series
        series = {}
        METHODS.each do |m|
          DISTANCE_MEASURES.each do |d|
            series["#{m}:#{d}"] = find_experiments(d, m).collect { |exp| {:k => exp.k, :x => exp.mean_auprc, :y => exp.mean_auroc } }
          end
        end
        series
      end


      def find_experiments distfn, classifier
        experiments = Experiment.find(:all, :conditions => @conditions.merge({
              :distance_measure => distfn, :method => classifier}),
          :order => "k ASC")
        experiments.delete_if { |x| x.source_matrix_ids != @source_matrix_ids }
        experiments
      end

    end
  end
end