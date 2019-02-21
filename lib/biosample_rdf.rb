require 'open-uri'
require 'json'
require 'json/ld'
require 'rdf/turtle'

module EBI
  module BioSamples
    module API
      def endpoint
        "https://www.ebi.ac.uk/biosamples/samples/"
      end

      def get(id)
        JSON.load(open(File.join(endpoint, id+".ldjson")))
      end
    end
  end
end

class BioSample
  include EBI::BioSamples::API

  def initialize(id)
    @id = id
    @data_raw = get(@id)
    @data = reshape(@data_raw)
  end
  attr_accessor :data_raw, :data

  def reshape(data_json)
    data = data_json

    # Add context
    data["@context"] = context
    data["mainEntity"]["@context"] = context

    # Add "@id" field with IRI
    record_id = data["identifier"]
    expended_id = expand_compactidentifier(record_id)
    data["identifier"] = expended_id
    data["@id"] = expended_id

    # Add "mainEntity/@id" field with IRI
    entity_id = data["mainEntity"]["identifiers"].first
    data["mainEntity"]["@id"] = expand_compactidentifier(entity_id)

    # Remove unnecessary fields
    data["mainEntity"].delete("identifiers")
    data["mainEntity"].delete("context")

    # Update structure of additional properties
    ap = data["mainEntity"]["additionalProperty"]
    data["mainEntity"]["additionalProperty"] = reshape_additional_properties(ap)

    data
  end

  def schema_org_context
    "https://schema.org/docs/jsonldcontext.json"
  end

  def context
    {
      "@base" => "http://schema.org/",
      "@vocab" => "http://schema.org/",
    }
  end

  def context_main
    {
      "@base" => "http://schema.org/",
      "@vocab" => "http://schema.org/",
      "url" => {
        "@id" => "url",
        "@type" => "http://www.w3.org/2001/XMLSchema#string"
      },
      "Sample" => {
        "@id" => "http://purl.obolibrary.org/obo/OBI_0000747",
      },
    }
  end

  def expand_compactidentifier(compactid)
    compactid.sub("biosamples:","http://identifiers.org/biosample/")
  end

  def reshape_additional_properties(additional_properties)
    additional_properties.map do |prop|
      prop["valueReference"] = update_value_reference(prop)
      prop["propertyID"] = update_property_id(prop)
      prop.compact
    end
  end

  def update_value_reference(prop)
    val_ref = prop["valueReference"]
    val_ref.map do |vr|
      {
        "@type" => "DefinedTerm",
        "@id" => vr["url"],
      }
    end
  rescue NoMethodError
    nil
  end

  # Property ID is not assinged in EBI BioSamples JSON-LD, return mock value
  def update_property_id(prop)
    val_ref = prop["valueReference"]
    val_ref.map do |vr|
      {
        "@type" => "DefinedTerm",
        "@id" => "http://some.one/annotates/this/property",
      }
    end
  rescue NoMethodError
    nil
  end

  def to_ttl
    tg = RDF::Graph.new << JSON::LD::API.toRdf(@data)
    tg.dump(:ttl, :base_uri => "http://schema.org/", :context => context_main)
  end
end

if __FILE__ == $0
  bsid = ARGV.first
  bs = BioSample.new(bsid)

  jsonld = JSON.dump(bs.data)
  puts jsonld

  ttl = bs.to_ttl
  puts ttl

  # Write json-ld
  # path_to_jsonld = File.join("./data/jsonld", bsid+".jsonld")
  # open(path_to_jsonld,"w"){|f| f.puts(jsonld) }

  # Write ttl
  # path_to_ttl = File.join("./data/ttl", bsid+".ttl")
  # open(path_to_ttl,"w"){|f| f.puts(ttl) }
end
