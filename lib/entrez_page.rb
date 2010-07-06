# Quickly parse a retrieved gene page from Entrez for summary information (all
# in the Summary section of the page).
class EntrezPage

  attr_reader :gene_id, :fields

  # Retrieve a page based on gene_id
  def initialize entrez_gene_id
    raise(ArgumentError, "Only integer Entrez gene IDs are allowed") unless entrez_gene_id.is_a?(Fixnum)

    @gene_id = entrez_gene_id

    require 'open-uri'
    # Load the page
    @summary = EntrezPage.extract_summary( open("http://www.ncbi.nlm.nih.gov/gene/#{entrez_gene_id}"){ |f| Hpricot(f) } )
    @fields  = EntrezPage.index_summary @summary
  end

  def inspect
    "#<#{self.class} gene_id: #{@gene_id}, symbol: '#{symbol || 'nil'}', full_name: \"#{full_name || 'nil'}\", organism: \"#{organism || 'nil'}\">"
  end

  # Extract the symbol from the page
  def symbol
    clean_definition "Official Symbol"
  end

  # Extract the Ensembl ID from the page if possible
  def ensembl_id
    regex_s = @summary.inner_html.scan(/Ensembl\:[A-Z0-9]+/)
    regex_s.size == 0 ? nil : regex_s.first.split(":").last
  end

  # Return synonyms if available
  def synonyms
    definition "Also known as"
  end

  # Return summary definition if available
  def summary
    definition "Summary"
  end

  # This returns the contents of the dl whose id is summaryDl (contains the info
  # we need for the rest of the methods).
  #
  # Most likely you'll only need it for troubleshooting.
  def summary_dl; @summary; end

  # Return gene full name if available
  def full_name
    clean_definition "Official Full Name"
  end

  def organism
    clean_definition "Organism"
  end

  # Same as definition, but also strips <span> and <a> tags
  def clean_definition field_or_idx
    d = definition(field_or_idx)
    if d =~ /\</
      d = d.split("<span").first if d =~ /\<span/
      d = Hpricot(d).search("//a").inner_html if d =~ /\<a/
    end
    d
  end

  # get the contents of the definition at index idx (or dt field name)
  def definition field_or_idx
    if field_or_idx.is_a?(Fixnum)
      @summary.search("//dd")[field_or_idx].inner_html
    elsif field_or_idx.is_a?(String)
      @fields.has_key?(field_or_idx) ? definition(@fields[field_or_idx]) : nil
    else
      raise ArgumentError, "definition needs a dt field string (without whitespace) or a fixnum"
    end
  end

  # Convert to hash.
  def to_h
    {:organism => organism, :full_name => full_name, :symbol => symbol, :gene_id => @gene_id, :synonyms => synonyms, :ensembl_id => ensembl_id, :summary => summary}
  end

  # Convert contents of this page to a hash that can be applied to the Gene model.
  def to_gene_attributes_h
    {:full_name => full_name, :symbol => symbol, :synonyms => synonyms, :ensembl_id => ensembl_id, :summary => summary}
  end

protected

  def self.extract_summary hpricot_doc
    hpricot_doc.search("//dl#summaryDl")
  end

  def self.index_summary s
    fields = {}
    count = 0
    s.search("//dt").each do |dt|
      key = dt.inner_html.split("\n").join(" ").squeeze(" ").strip # clean the key of whitespace and such
      fields[key] = count
      count += 1
    end

    fields
  end

end