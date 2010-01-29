# The Experiment class is the base class for different types of analyses you can
# run on matrices.
#
# = Goals
# * Reproducibility
# * Parallelization of computational analyses (not necessarily on the same arch)
# * Encapsulation of external binaries and scripts
# * Data analysis and visualization
#
# = Design
# == Database Storage
# * A single prediction Matrix, predict_matrix, which is the matrix of the
#   species for which we want to make predictions.
# * Multiple source matrix linkers, of type Source, which point to the matrices
#   from which the predictions will be generated.
# * One column for each specification needed to run the binary or script which
#   performs the actual calculations. For example, JohnExperiment uses method,
#   k, min_genes, and several others. Not every sub-type need use every column.
# * The run_result, which is either nil or the exit code given by the script or
#   binary when it finished.
# * started_at, which specifies when the user executed Experiment.run.
# * completed_at, which specifies when the Experiment finished.
# * updated_at and created_at, which are Rails default columns giving the last
#   edit as well as creation.
# * Certain sub-types may have additional database associations. For example,
#   each JohnExperiment and MartinExperiment will have many Roc instances, which
#   store the ROC scores for each experiment (by phenotype).
#
# == Working Directory
# Since matrix and experiment calculations occur outside of the Rails
# environment -- typically as binaries or scripts executed through the shell --
# each unique instance of the Experiment class makes use of files stored in the
# instance's working directory in the filesystem.
#
# As with Matrix, the function prepare_inputs is responsible for initializing
# the working directory, which is within the predict_matrix Matrix's working
# directory (e.g., crossval/tmp/work/matrix_1/experiment_1).
#
# prepare_inputs, based on the predict_matrix and sources, copies the necessary
# input files into the experiment working directory from the matrix working
# directory. It is best to make sure the Matrix working directories have already
# been created (using Matrix::prepare_inputs on a specific matrix instance). For example, do:
#
#  m = Matrix.find 1
#  m.prepare_inputs
#  x = m.experiments.first
#  x.prepare_inputs
#
# Each child class of Experiment should itself specify the inputs to copy (or
# generate).
#
# == Outputs
# Output files are mostly stored directly in the experiment working directory,
# and differ between JohnExperiment and MartinExperiment.
#
# Files that should appear in both:
# * log.timestamp, e.g., log.20100128222110. The timestamp is given by started_at.
#   This file contains the standard output console results of the execution.
# * error_log.timestamp, e.g., error_log.20100128222110, containing the standard
#   error console results of the execution.
# * One or more predictions directories.
#
# == Predictions Directories (Outputs of the Binary or Script)
# These should be named corresponding to the test set, for cross-validation;
# e.g., when testset.10-0 is withheld, predictions0 should be generated.
#
# Each predictions directory should contain one file per phenotype to be
# predicted (e.g., one for each phenotype/column in the predict_matrix).
#
# Each phenotype prediction file should have two header lines. They really don't
# do anything, so you can use the first one for comments. The second one gives
# the contents of each column, but again -- isn't really used.
#
# There should be two columns in the prediction files -- one for the gene (row
# in the matrix) and the other for the likelihood score / probability predicted
# that this gene causes the phenotype.
#
# After the binary finishes running, the sort script will be executed by your
# Experiment object. This takes the results in the predictions directories and
# sorts each phenotype in to a corresponding file in the results directory. The
# results directory is named as results.timestamp, e.g., results.20100128222110,
# and the timestamp should correspond to the log and error_log files.
#
# The sort files will be in descending order (using Unix sort) by prediction
# score.
#
# The prediction score should be between 0 and 1, and may or may not represent a
# probability.
#
# Upon completion of sort, the statistical module will read in the results and
# compute AUCs for each phenotype. These AUCs are stored in Roc objects. Again,
# each Experiment has_many :rocs, so you can access them as x.rocs (where x is
# an Experiment). You can also view them by going to the show action for an
# Experiment in your web browser, e.g.:
#
# http://draco.icmb.utexas.edu:3002/matrices/1/experiments/17
#
# Note that the Matrix (1) in the above path is the predict_matrix for Experiment 17.
#
class Experiment < ActiveRecord::Base
  acts_as_commentable
  belongs_to :predict_matrix, :class_name => "Matrix", :readonly => true
  delegate :column_species, :to => :predict_matrix
  alias :predict_species :column_species
  has_many :sources, :dependent => :destroy
  has_many :source_matrices, :through => :sources, :foreign_key => :source_matrix_id, :class_name => "Matrix", :readonly => true
  has_many :rocs
  accepts_nested_attributes_for :sources, :allow_destroy => true

  named_scope :not_run, :conditions => {:total_auc => nil}
  named_scope :not_completed, :conditions => {:completed_at => nil}
  named_scope :not_started, :conditions => {:started_at => nil}

  # Make sure sources are valid
  validates_associated :sources

  AVAILABLE_METHODS = {}
  AVAILABLE_DISTANCE_MEASURES = {}
  
  # Print a title for this experiment
  def title
    "#{self.argument_string} [predicting #{self.predict_matrix_id}]"
  end

  def unique_descriptor
    "#{self.id}: #{self.title}"
  end

  #def prepare_inputs
  #end
  
  def dir_exists? dir
    File.exists?(dir)
  end

  def root_exists?
    dir_exists?(self.root)
  end

  def root
    self.predict_matrix.root + "experiment_#{self.id}"
  end

  # Copy input files from each of the source matrices and the predict matrix.
  # Does nothing if the experiment directory already exists.
  def prepare_inputs_internal &block
    unless self.root_exists?
      logger.info("Preparing new inputs for experiment #{self.id}")

      self.prepare_dir

      yield block
    end
  end
  
  # To be called by a Worker object, usually.
  def run
    before_run # sets and saves started_at

    Dir.chdir(self.root) do
      STDERR.puts("Command: #{self.command_string}")
      `#{self.command_string_with_pipes}`

      # Get the exit status when the bin finishes.
      self.run_result = $?.to_i
    end
    # Expect a great deal of time between the beginning of this function and the
    # end. That's why we're saving again -- because the binary will have returned
    # 0 or aborted or who knows what.
    self.save!

    if self.run_result == 0
      # Calculate results and save again.
      after_run
    else
      logger.error("Execution error for binary. Returned: #{self.run_result}")
    end
  end
  
  def log_file
    "log.#{time_to_file_suffix(self.started_at || Time.now)}"
  end

  def error_log_file
    "error_log.#{time_to_file_suffix(self.started_at || Time.now)}"
  end
  
  #def argument_string
  #end

  def has_been_run?
    !self.total_auc.nil?
  end

  def aucs_file
    "aucs.#{time_to_file_suffix(self.started_at || Time.now)}"
  end

  def results_dir
    "results.#{time_to_file_suffix(self.started_at || Time.now)}"
  end

  def results_path
    self.root + self.results_dir
  end

  # Make sure to define bin_path in your child class.
  #def bin_path
  #
  #end

  def sort_bin_path
    Rails.root + "bin/sortall.pl"
  end

  def aucs_bin_path
    Rails.root + "bin/calculate_aucs.py"
  end
  
  def sort_results
    Dir.chdir(self.root) do
      `#{self.sort_bin_path} #{self.results_dir} predictions* 2>> #{self.error_log_file} 1>> #{self.log_file}`
    end
  end

  # Clean out the temporary variables used for a run.
  # Be careful doing this -- particularly if this is being run in parallel, e.g.
  # jobs on different machines.
  def reset_for_new_run!
    self.started_at   = nil
    self.completed_at = nil
    self.run_result   = nil
    self.total_auc    = nil
    self.save!

    self.clean_predictions_dirs
    self.clean_temporary_files

    self # allow chaining
  end

  def reset_inputs
    `rm -rf #{self.root}`
    self.prepare_inputs unless self.sources.size == 0
  end

  def command_string
    "#{self.bin_path} #{self.argument_string}"
  end

  def command_string_with_pipes
    "#{self.command_string} 2>> #{self.error_log_file} 1>> #{self.log_file}"
  end

  # Get the points that make up the ROC plot for this experiment
  def roc_line
    roc_y_values = self.rocs.collect { |r| r.auc }
    roc_x_values = Array.new(roc_y_values.size) { |r| r / roc_y_values.size.to_f }
    roc_x_values.zip roc_y_values.sort
  end
  
  def source_species
    self.sources.collect{ |m| m.source_species }.sort{ |a,b| Species.new(b) <=> Species.new(a) }
  end

  def source_species_to_s
    self.source_species.join(",")
  end

protected

  # Update the 'started_at' value and save. This needs to be fixed so it doesn't
  # call ActiveRecord::save! which will change other timestamps as well.
  def before_run
    self.started_at = Time.now
    self.save!
  end

  # Sort/calculate ROCs for an experiment. You can override this function for things
  # like JohnDistribution so you calculate other things instead of ROCs.
  def after_run
    sort_results_and_calculate_rocs!
  end

  def sort_results_and_calculate_rocs!
    # Call the script which sorts results into a separate directory.
    self.sort_results

    # Calculating the AUCs also marks the task as completed and saves the record.
    STDERR.puts("Calling calculate_rocs!")
    self.calculate_rocs!
    STDERR.puts("Done calling calculate_rocs!")
  end

  def calculate_rocs!
    aucs = []
    STDERR.puts("Calling Roc.calculate")
    Roc.calculate(self.id, self.results_path).each do |roc|
      roc.save!
      aucs << roc.auc
    end

    self.total_auc = mean aucs
    self.completed_at = Time.now
    STDERR.puts("Calling save_without_timestamping!")
    self.save!
    self
  end

  def calculate_aucs_old
    Dir.chdir(self.root) do
      aucs_file = self.aucs_file
      `#{self.aucs_bin_path} #{self.results_dir} 1>> #{aucs_file} 2>> #{self.error_log_file}`
      self.total_auc = calculate_average_auc(read_aucs(aucs_file))
    end
    
    self.completed_at = Time.now
    self.save_without_timestamping!
  end

  # Takes an absolute path, mind you. Creates a directory. By default, creates
  # the directory for this experiment.
  def prepare_dir(dir = self.root)
    Dir.mkdir(dir) unless dir_exists?(dir)
  end
  
  # BROKEN (I think)
  # Force a save without updating timestamps.
  # Used to update total_auc, which is not technically part of the model.
  # Also -- for completed_at and started_at
  def save_without_timestamping!
    class << self
      def record_timestamps; false; end
    end
    save!
    class << self
      remove_method :record_timestamps
    end
  end
  
  # Copy testsets from the predict_matrix to the experiment directory.
  def copy_testsets(prefix = "testset")
    # Copy testsets if applicable
    self.predict_matrix.children_file_paths(prefix).each do |child_path|
      FileUtils.cp(child_path, self.root)
    end
  end

  # Generates row and column files, makes sure they're in the right directory.
  # Only call from within prepare_inputs_internal, as this guarantees we're in
  # the correct directory and such.
  def prepare_standard_inputs
      cell_files = self.copy_source_matrix_inputs

      # Generate predict_rows file
      self.generate_row_file(cell_files)
      self.generate_column_file

      # Only copy the predict matrix cells file if it didn't come from one of the
      # source matrices.
      unless cell_files.include?(self.predict_matrix.cell_file_path)
        FileUtils.cp(self.predict_matrix.cell_file_path, self.root)
      end
  end
end


# Converts a datetime (timestamp) to a numeric string without spaces.
def time_to_file_suffix t
  t.utc.strftime("%Y%m%d%H%M%S")
end


# Calculates a hash/dict and calculates the average (mean) of the values
def calculate_average_auc hash_of_aucs
  total = 0.0
  hash_of_aucs.values.each { |value| total += value }
  total / hash_of_aucs.size.to_f
end


# Helper for reading a file with the results of a prediction
def read_aucs file
  f = File.new(file, "r")
  h = {}
  while line = f.gets
    line.chomp!
    fields = line.split("\t")

    # Insert in the hash
    h[ fields[0].to_i ]   =    fields[1].to_f
  end
  f.close

  h
end

# Calculates the mean of a set
def mean l
  total = 0
  l.each { |x| total += x }
  total / l.size.to_f
end
