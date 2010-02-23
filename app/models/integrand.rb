class Integrand < ActiveRecord::Base
  belongs_to :integrator, :readonly => true
  belongs_to :experiment, :readonly => true

  # Accessor for the weight returns a rational number.
  def weight
    @weight ||= Rational(weightn, weightd)
  end

  # Setter for the weight stores it as a rational number.
  # If it can't be read, this usually sets it as 0/1. See also string_ext.rb in lib/.
  def weight=val
    @weight = val.to_r
    weightn = @weight.numerator
    weightd = @weight.denominator
  end
end
