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
                    .gsub('(','\(')
                    .gsub(')','\)')
  end

  def write_prefixes
    puts <<~TTLPREFIX
      @prefix : <http://schema.org/> .
      @prefix idorg: <http://identifiers.org/biosample/> .
      @prefix dct: <http://purl.org/dc/terms/> .
      @prefix ddbj: <http://ddbj.nig.ac.jp/biosample/> .
      @prefix ddbjont: <http://ddbj.nig.ac.jp/ontologies/biosample/> .
      @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
      @prefix xsd: <https://www.w3.org/2001/XMLSchema#> .

    TTLPREFIX
  end

  def sample_info(attrs)
    h = attrs.to_h
    @sample[:id] = h["accession"]
    @sample[:submission_date] = h["submission_date"]
    @sample[:last_update] = h["last_update"]
    @sample[:publication_date] = h["publication_date"]
  end

  def attribute_key(attrs)
    h = attrs.to_h
    a_name = h["attribute_name"] ? escape_chars(h["attribute_name"]) : nil
    h_name = h["harmonized_name"] ? escape_chars(h["harmonized_name"]) : nil
    d_name = h["display_name"] ? escape_chars(h["display_name"]) : nil
    @sample[:additional_properties] << {
      attribute_name: a_name,
      harmonized_name: h_name,
      display_name: d_name,
    }
  end

  def attribute_value
    h = @sample[:additional_properties].pop
    h[:property_value] = escape_chars(@inner_text)
    @sample[:additional_properties] << h
  end

  # idorg:SAMD00109171
  # a ddbjont:BioSampleRecord ;
  # :identifier "SAMD00109171" ;
  # dct:identifier "SAMD00109171" ;
  # :description "Bisulfite sequencing sample of iPSC_1" ;
  # rdfs:label "Bisulfite sequencing sample of iPSC_1" ;
  #
  # :dateCreated "2019-01-16T14:05:50.947"^^:Date ;
  # :dateModified "2020-06-28T05:02:22.320"^^:Date ;
  #
  # :additionalProperty
  #   ddbjont:SAMD0010917\#sample_name,
  #   ddbjont:SAMD0010917\#cell_line,
  #   ddbjont:SAMD0010917\#cell_type,
  #   ddbjont:SAMD0010917\#replicate,
  #   ddbjont:SAMD0010917\#sex .
  #
  # ddbjont:SAMD0010917\#sample_name a :PropertyValue ;
  #    :name "sample_name" ;
  #    :value "iPSC_1" .

  def output_turtle
    out = "\n"
    out << "idorg:#{@sample[:id]}\n"
    out << "  a ddbjont:BioSampleRecord ;\n"

    # out << "  :identifier \"biosample:#{@sample[:id]}\" ;\n"
    out << "  dct:identifier \"#{@sample[:id]}\" ;\n"

    # out << "  :description \"#{@sample[:description_title]}\" ;\n"
    out << "  dct:description \"#{@sample[:description_title]}\" ;\n"
    out << "  rdfs:label \"#{@sample[:description_title]}\" ;\n"

    out << "  dct:created \"#{@sample[:submission_date]}\"^^xsd:dateTime ;\n"
    out << "  dct:modified \"#{@sample[:last_update]}\"^^xsd:dateTime ;\n"
    out << "  dct:issued \"#{@sample[:publication_date]}\"^^xsd:dateTime"

    n = @sample[:additional_properties].size
    if n > 0
      out << " ;\n" # Close :dateModified statement
      out << "  :additionalProperty\n"

      @sample[:additional_properties].each_with_index do |p,i|
        name = p[:harmonized_name] ? p[:harmonized_name] : p[:attribute_name]
        qname = URI.encode_www_form_component(name)
        suffix = i != n-1 ? ',' : '.'
        out << "    <http://ddbj.nig.ac.jp/biosample/#{@sample[:id]}##{qname}> #{suffix}\n"
      end

      out << "\n"

      @sample[:additional_properties].each do |p|
        name  = p[:harmonized_name] ? p[:harmonized_name] : p[:attribute_name]
        qname = URI.encode_www_form_component(name)
        value = p[:property_value]
        out << "<http://ddbj.nig.ac.jp/biosample/#{@sample[:id]}##{qname}> a :PropertyValue ;\n"

        out << "  :name \"#{name}\" ;\n"
        out << "  :value \"#{value}\" .\n"
      end
    else
      out << " .\n" # Close :dateModified statement
    end

    puts out
  end
end
