$LOAD_PATH << __dir__

require 'lib/biosample'

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
