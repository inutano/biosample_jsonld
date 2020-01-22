require 'nokogiri'

class BioSampleXML < Nokogiri::XML::SAX::Document
  def initialize
    prefixes
    @node = ""
    @id = ""
    @properties = []
  end

  def prefixes
    puts "@base <http://schema.org/> ."
    puts "@prefix bs: <http://identifiers.org/biosample/> ."
    puts "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> ."
    puts "@prefix obo: <http://purl.obolibrary.org/obo/> ."
    puts "@prefix dct: <http://purl.obolibrary.org/obo/> ."
    puts ""
  end

  def sample(attrs)
    h = attrs.to_h
    @id = h["accession"]
    puts "bs:#{@id} a <DataRecord>;"
    puts "  <dateCreated> \"#{h["submission_date"]}\"^^<Date>;"
    puts "  <dateModified> \"#{h["last_update"]}\"^^<Date>;"
    puts "  <identifier> \"biosample:#{@id}\";"
    puts "  <isPartOf> <https://www.ebi.ac.uk/biosamples/samples>;"
    puts "  <mainEntity> ["
    puts "    a <Sample>,"
    puts "    obo:OBI_0000747;"
    puts "    <name> \"#{@id}\";"
    puts "    <identifier> \"biosample:#{@id}\";"
    puts "    dct:identifier \"#{@id}\";"
    puts "    <subjectOf> \"https://www.ebi.ac.uk/ena/data/view/#{@id}\";"
  end

  def description(str)
    puts "    <description> \"#{str}\";"
  end

  def attributes
    puts "    <additionalProperty> ["
    n = @properties.size
    @properties.each.with_index do |p,i|
      puts "a <PropertyValue>;"
      puts "<name> \"#{p["attribute_name"]}\";"
      if size-1 != i
        puts "    ], ["
      end
    end
    puts "    ];"
  end

  def attribute(attrs)
    h = attrs.to_h
    @properties <<
  end

  def start_element(name, attrs = [])
    case name
    when "BioSample"
      sample(attrs)
    when "Title"
      @node = name
    when "Package"
    when "Attributes"
      attr_start
    when "Attribute"
      @node = name
      attribute(attrs)
    when "Links"
    end
  end

  def characters(string)
    case @node
    when "Title"
      description(string)
    when "Attribute"
      attr_end
    end
  end

  def end_element(name)
  end
end
