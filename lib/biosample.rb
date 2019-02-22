require 'json'
require 'json/ld'
require 'rdf/turtle'

require 'lib/ebi/biosamples/api'

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
    main_entity = data_json.delete("mainEntity")

    # Context
    data["@context"] = jsonld_context

    # Data type
    data_type = [data, main_entity].map{|ent| ent["@type"] }.flatten

    # Add "@id" field with IRI
    record_id = data["identifier"]
    expended_id = expand_compactidentifier(record_id)
    data["identifier"] = record_id.sub("biosamples:","")
    data["@id"] = expended_id

    # Remove unnecessary fields
    main_entity.delete("identifiers")
    main_entity.delete("context")
    main_entity.delete("@context")

    # Update structure of additional properties
    ap = main_entity["additionalProperty"]
    main_entity["additionalProperty"] = reshape_additional_properties(ap)

    # Change "dataset" domain type
    ds_arr = main_entity.delete("dataset")
    main_entity["dataset"] = ds_arr.map{|ds| {"@id" => ds, "@type" => "Dataset"} }

    # Merge main entity
    merged = data.merge(main_entity)
    merged["@type"] = data_type
    merged
  end

  def schema_org_context
    "https://schema.org/docs/jsonldcontext.json"
  end

  def jsonld_context
    {
      "@base" => "http://schema.org/",
      "@vocab" => "http://schema.org/",
      "url" => {
        "@type" => "http://www.w3.org/2001/XMLSchema#string",
      },
      "dateCreated" => {
        "@type" => "http://www.w3.org/2001/XMLSchema#dateTime",
      },
      "dateModified" => {
        "@type" => "http://www.w3.org/2001/XMLSchema#dateTime",
      },
      "Sample" => {
        "@id" => "http://purl.obolibrary.org/obo/OBI_0000747",
      },
      "name" => {
        "@type" => "http://www.w3.org/2001/XMLSchema#string",
      },
      "value" => {
        "@type" => "http://www.w3.org/2001/XMLSchema#string",
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
        "@value" => "annotated_property_name",
      }
    end
  rescue NoMethodError
    nil
  end

  def to_ttl
    tg = RDF::Graph.new << JSON::LD::API.toRdf(@data)
    tg.dump(:ttl, base_uri: "http://schema.org/", prefixes: ttl_prefixes)
  end

  def ttl_prefixes
    {
      xsd: "http://www.w3.org/2001/XMLSchema#"
    }
  end
end
