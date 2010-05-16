class String
  # Convert to a rational number
  def to_r
    a = split("/")
    a.size == 2 ? Rational(a[0].to_i,a[1].to_i) : Rational(to_i,1)
  end

  # Convert the string to a species abbreviation
  def speciesize
    str = self.downcase
    if str =~ /mouse/ || str =~ /mus/ || str =~ /^mm$/
      'Mm'
    elsif str =~ /human/ || str =~ /homo/ || str =~ /sapiens/ || str =~ /^hs$/
      'Hs'
    elsif str =~ /arabidopsis/ || str =~ /thaliana/ || str =~ /^at$/
      'At'
    elsif str =~ /yeast/ || str =~ /saccharomyces/ || str =~ /cerev/ || str =~ /^sc$/
      'Sc'
    elsif str =~ /worm/ || str =~ /elegans/ || str =~ /^ce$/
      'Ce'
    elsif str =~ /oryza/ || str =~ /^os$/
      'Os'
    else
      self
    end
  end
end