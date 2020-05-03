require 'nokogiri'
require "cgi/escape"

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
    @inner_text = escape_chars(string)
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

  def escape_chars(char)
    CGI.unescapeHTML(char)
                    .gsub("\n",'')
                    .gsub(/^\s+$/,'')
                    .gsub('\\','\\\\\\')
                    .gsub('"','\"')
                    .gsub(';','\;')
  end

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
    a_name = h["attribute_name"] ? escape_chars(h["attribute_name"]) : ""
    h_name = h["harmonized_name"] ? escape_chars(h["harmonized_name"]) : ""
    d_name = h["display_name"] ? escape_chars(h["display_name"]) : ""
    @sample[:additional_properties] << {
      attribute_name: a_name,
      harmonized_name: h_name,
      display_name: d_name,
    }
  end

  def attribute_value
    h = @sample[:additional_properties].pop
    h[:property_value] = @inner_text
    @sample[:additional_properties] << h
  end

  def output_turtle
    out = ""
    out << "b:#{@sample[:id]} a :DataRecord;\n"
    out << " :dateCreated \"#{@sample[:submission_date]}\"^^:Date;\n"
    out << " :dateModified \"#{@sample[:last_update]}\"^^:Date;\n"
    out << " :identifier \"biosample:#{@sample[:id]}\";\n"
    out << " :isPartOf [ a :Dataset; :identifier e:samples ];\n"
    out << " :mainEntity ["
    out << "  a :Sample, o:OBI_0000747;\n"
    out << "  :name \"#{@sample[:id]}\";\n"
    out << "  :description \"#{@sample[:description_title]}\";\n"
    out << "  :identifier \"biosample:#{@sample[:id]}\";\n"
    out << "  d:identifier \"#{@sample[:id]}\";\n"

    n = @sample[:additional_properties].size
    if n != 0
      out << "  :additionalProperty\n"

      @sample[:additional_properties].each_with_index do |p,i|
        name  = p[:harmonized_name] ? p[:harmonized_name] : p[:attribute_name]
        value = p[:property_value]
        comma = i != n-1 ? "," : ""

        out << "   [\n"
        out << "     a :PropertyValue;\n"
        out << "     :name \"#{name}\";\n"
        out << "     :value \"#{value}\"\n"
        out << "   ]#{comma}\n"
      end
    end

    out << " ].\n"

    puts out
  end
end
