require 'open-uri'
require 'json'
require 'json/ld'
require 'rdf/turtle'

module EBI
  class BioSchema
    class BioSample
      class API
        class << self
          def endpoint
            "https://www.ebi.ac.uk/biosamples/samples/"
          end

          def get_json(id)
            JSON.load(open(File.join(endpoint, id+".ldjson")))
          end

          def value_reference(value_reference)
            if value_reference
              value_reference.map do |vr|
                {
                  "@type" => "DefinedTerm",
                  "@id" => vr["url"],
                }
              end
            end
          end

          def property_id(value_reference)
            if value_reference
              {
                "@type" => "DefinedTerm",
                "@id" => "http://some.one/annotates/this/property",
              }
            end
          end

          def get(id)
            data_json = get_json(id)
            properties = data_json["mainEntity"]["additionalProperty"]
            new_props = properties.map do |prop|
              val_ref = value_reference(prop["valueReference"])
              prop_id = property_id(prop["valueReference"])
              pr = {
                "@type" => "PropertyValue",
                "name" => prop["name"],
                "value" => prop["value"],
              }
              pr["propertyID"] = prop_id if prop_id
              pr["valueReference"] = val_ref if val_ref
              pr
            end
            data_json["mainEntity"]["additionalProperty"] = new_props
            data_json["@id"] = data_json["identifier"].sub("biosamples:","http://identifiers.org/biosample/")
            data_json
          end

          def get_jsonld(id)
            JSON.dump(get(id))
          end

          def schema_org_context
            "https://schema.org/docs/jsonldcontext.json"
          end

          def jsonld_with_expanded_context(id)
            data = get(id)
            data["@context"] = schema_org_context
            data["mainEntity"]["@context"] = schema_org_context
            data
          end

          def get_ttl(id)
            jsonld = jsonld_with_expanded_context(id)
            tg = RDF::Graph.new << JSON::LD::API.toRdf(jsonld)
            tg.dump(:ttl, :base_uri => "http://schema.org/")
          end
        end
      end
    end
  end
end

if __FILE__ == $0
  puts EBI::BioSchema::BioSample::API.get_jsonld("SAMEA1652233")
  puts EBI::BioSchema::BioSample::API.get_ttl("SAMEA1652233")
end
