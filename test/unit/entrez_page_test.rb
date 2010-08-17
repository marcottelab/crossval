require 'test_helper'

class EntrezPageTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end

  test "entrez page for human gene " do
    page = EntrezPage.new 652
    assert !page.symbol.nil?
    assert !page.symbol.blank?
    assert page.symbol == "BMP4"
    assert page.organism == "Homo sapiens"
    assert page.full_name == "bone morphogenetic protein 4"
  end

  test "entrez page for arabidopsis gene " do
    page = EntrezPage.new 817081
    assert !page.symbol.nil?
    assert !page.symbol.blank?
    assert page.symbol == "AT2G25430"
    assert page.organism == "Arabidopsis thaliana"
    assert page.full_name == "epsin N-terminal homology (ENTH) domain-containing protein"
  end
end
