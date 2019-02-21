$LOAD_PATH << __dir__

require 'lib/biosample'

if __FILE__ == $0
  bsid = ARGV.first
  bs = BioSample.new(bsid)

  # Write json-ld
  jsonld = JSON.dump(bs.data)
  path_to_jsonld = "./#{bsid}.jsonld"
  open(path_to_jsonld,"w"){|f| f.puts(jsonld) }

  # Write ttl
  ttl = bs.to_ttl
  path_to_ttl = "./#{bsid}.ttl"
  open(path_to_ttl,"w"){|f| f.puts(ttl) }
end
