module MetaHelper
  def cached_matrix_list
    Fastknn.cached.blank? ? "None" : Fastknn.cached.join(", ")
  end
end
