class String
  # Convert to a rational number
  def to_r
    a = split("/")
    a.size == 2 ? Rational(a[0].to_i,a[1].to_i) : Rational(to_i,1)
  end
end