class JohnDistribution < JohnPredictor


protected
  # In the parent this is used to calculate and load ROCs. Here, we don't want
  # to do anything with it...for now. It'll be overridden again in JohnDistribution.
  def after_run
    raise NotImplementedError, "Need to write code to produce a distribution for a distance measure."
  end

end
