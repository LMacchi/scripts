#!/opt/puppetlabs/puppet/bin/ruby

require "net/https"
require "uri"
require "json"
$not_found = Array.new
mod_list = ARGV[0]

if ARGV.empty?
  puts "USAGE: #{$0} /path/to/modules/list"
  exit 1
end

file = File.open(mod_list, "r") do |fh|
  fh.each_line do |mod|
    mod.chomp!
    url = "https://forgeapi.puppet.com:443/v3/modules/#{mod}"
    uri = URI.parse(url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri, {'User-Agent' => 'test'})

    response = http.request(request)
    #puts "#{mod} response code is #{response.code}"

    if response.code == '200'

      parsed = JSON.parse(response.body)

      full_name = parsed["slug"]
      version = parsed["current_release"]["version"]
      # API returns author-module but r10k needs author/module
      full_name.gsub!(/-/, '/')
      puts "mod \'#{full_name}\', \'#{version}\'"
    else
      $not_found.push(mod)
    end
  end

  puts "\n\nModules not found: #{$not_found}"
end
