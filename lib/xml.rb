require 'nokogiri'

class BioSampleXML < Nokogiri::XML::SAX::Document
  def initialize
    write_prefixes

    @inner_text = ""

    @sample_properties = {
      id: "",
      submission_date: "",
      last_update: "",
      description_title: "",
      additional_properties: [],
    }
  end

  #
  # SAX Event triggers
  #

  def start_element(name, attrs = [])
    case name
    when "BioSample"
      sample(attrs)
    when "Attribute"
      attribute(attrs)
    end
  end

  def characters(string)
    @inner_text = string
  end

  def end_element(name)
    case name
    when "Attribute"
      attribute_value
    when "Title"
      @sample_properties[:description_title] = @inner_text
    when "BioSample"
      output_turtle
    end
  end

  #
  # functions
  #

  def write_prefixes
    puts "@base <http://schema.org/> ."
    puts "@prefix bs: <http://identifiers.org/biosample/> ."
    puts "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> ."
    puts "@prefix obo: <http://purl.obolibrary.org/obo/> ."
    puts "@prefix dct: <http://purl.obolibrary.org/obo/> ."
    puts ""
  end

  def sample(attrs)
    h = attrs.to_h
    @sample_properties[:id] = h["accession"]
    @sample_properties[:submission_date] = h["submission_date"]
    @sample_properties[:last_update] = h["last_update"]
  end

  def attribute(attrs)
    h = attrs.to_h
    @sample_properties[:additional_properties] << {
      attribute_name: h["attribute_name"],
      harmonized_name: h["harmonized_name"],
      display_name: h["display_name"],
    }
  end

  def attribute_value
    h = @sample_properties[:additional_properties].pop
    h[:property_value] = @inner_text
    @sample_properties[:additional_properties] << h
  end

  def output_turtle
    puts "bs:#{@sample_properties[:id]} a <DataRecord>;"
    puts "  <dateCreated> \"#{@sample_properties[:submission_date]}\"^^<Date>;"
    puts "  <dateModified> \"#{@sample_properties[:last_update]}\"^^<Date>;"
    puts "  <identifier> \"biosample:#{@sample_properties[:id]}\";"
    puts "  <isPartOf> <https://www.ebi.ac.uk/biosamples/samples>;"
    puts "  <mainEntity> ["
    puts "    a <Sample>, obo:OBI_0000747;"
    puts "    <name> \"#{@sample_properties[:id]}\";"
    puts "    <identifier> \"biosample:#{@sample_properties[:id]}\";"
    puts "    dct:identifier \"#{@sample_properties[:id]}\";"
    puts "    <subjectOf> \"https://www.ebi.ac.uk/ena/data/view/#{@sample_properties[:id]}\";"
    puts "    <description> \"#{@sample_properties[:description_title]}\";"

    puts "    <additionalProperty> ["
    n = @sample_properties[:additional_properties].size
    @sample_properties[:additional_properties].each_with_index do |p,i|
      puts "      a <PropertyValue>;"
      puts "      <name> \"#{p[:harmonized_name] ? p[:harmonized_name] : p[:attribute_name]}\";"
      puts "      <value> \"#{p[:property_value]}\""
      if i != n-1
        puts "    ], ["
      end
    end
    puts "    ] ."
    puts "  ] ."
  end
end
