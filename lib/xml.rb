require 'nokogiri'

class BioSampleXML < Nokogiri::XML::SAX::Document
  def initialize
    write_prefixes

    @inner_text = ""

    @sample = {
      id: "",
      submission_date: "",
      last_update: "",
      description_title: "",
      additional_properties: [],
    }
  end

  def initialize_stack
    @inner_text = ""

    @sample = {
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
      sample_info(attrs)
    when "Attribute"
      attribute_key(attrs)
    end
  end

  def characters(string)
    @inner_text = string.gsub("\n",'')
                    .gsub(/^\s+$/,'')
                    .gsub('\\','\\\\\\')
                    .gsub('"','\"')
                    .gsub(';','\;')
  end

  def end_element(name)
    case name
    when "Attribute"
      attribute_value
    when "Title"
      @sample[:description_title] = @inner_text
    when "BioSample"
      output_turtle
      initialize_stack
    end
  end

  #
  # functions
  #

  def write_prefixes
    puts "@prefix : <http://schema.org/> ."
    puts "@prefix e: <https://www.ebi.ac.uk/biosamples/> ."
    puts "@prefix b: <http://identifiers.org/biosample/> ."
    puts "@prefix o: <http://purl.obolibrary.org/obo/> ."
    puts "@prefix d: <http://purl.org/dc/terms/> ."
    puts ""
  end

  def sample_info(attrs)
    h = attrs.to_h
    @sample[:id] = h["accession"]
    @sample[:submission_date] = h["submission_date"]
    @sample[:last_update] = h["last_update"]
  end

  def attribute_key(attrs)
    h = attrs.to_h
    @sample[:additional_properties] << {
      attribute_name: h["attribute_name"],
      harmonized_name: h["harmonized_name"],
      display_name: h["display_name"],
    }
  end

  def attribute_value
    h = @sample[:additional_properties].pop
    h[:property_value] = @inner_text
    @sample[:additional_properties] << h
  end

  def output_turtle
    out = ""
    out << "b:#{@sample[:id]} a :DataRecord;"
    out << " :dateCreated \"#{@sample[:submission_date]}\"^^:Date;"
    out << " :dateModified \"#{@sample[:last_update]}\"^^:Date;"
    out << " :identifier \"biosample:#{@sample[:id]}\";"
    out << " :isPartOf [ a :Dataset; :identifier e:samples ];"
    out << " :mainEntity [ a :Sample, o:OBI_0000747;"
    out << " :name \"#{@sample[:id]}\";"
    out << " :description \"#{@sample[:description_title]}\";"
    out << " :identifier \"biosample:#{@sample[:id]}\";"
    out << " d:identifier \"#{@sample[:id]}\";"

    n = @sample[:additional_properties].size
    if n != 0
      out << " :additionalProperty"

      @sample[:additional_properties].each_with_index do |p,i|
        name  = p[:harmonized_name] ? p[:harmonized_name] : p[:attribute_name]
        value = p[:property_value]
        comma = i != n-1 ? "," : ""

        out << " [ a :PropertyValue; :name \"#{name}\"; :value \"#{value}\" ]#{comma}"
      end
    end

    out << " ]."

    puts out
  end
end
