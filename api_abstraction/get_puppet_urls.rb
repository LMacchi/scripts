#!/opt/puppetlabs/puppet/bin/ruby

def return_urls(orch_file)

  if orch_file.empty?
    puts "This method requires a file as argument"
    exit 2
  end

  if ! File.exist?(orch_file)
    puts "File #{orch_file} does not exist. No settings could be read"
    exit 2
  end

  puppet_url = Hash.new()

  File.open(orch_file, "r") do |fh|
    fh.each_line do |line|
      if line.match(/(master-url|puppetdb-url|classifier-service): "https:\/\/(\S+):(\d+)/)
        host = $2
        port = $3
        service = $1.gsub(/(-\w+)/,"")
        puppet_url[service] = "https://#{host}:#{port}"
      end
    end
  end

  return puppet_url
end
