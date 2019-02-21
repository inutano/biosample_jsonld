require 'open-uri'

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
