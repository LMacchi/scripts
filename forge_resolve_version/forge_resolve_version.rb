#!/opt/puppetlabs/puppet/bin/ruby

require "net/https"
require "uri"
require "json"
$not_found = Array.new()
$decom = Array.new()
$deps = Array.new()
$mods = Hash.new()
mod_list = ARGV[0]
puppetfile = "Puppetfile_new"


if ARGV.empty?
  puts "USAGE: #{$0} /path/to/modules/list"
  exit 2
end

def findModuleData(mod)
  url = "https://forgeapi.puppet.com:443/v3/modules/#{mod}"
  uri = URI.parse(url)

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Get.new(uri.request_uri, {'User-Agent' => 'test'})

  response = http.request(request)

  if response.code == '200'
    parsed = JSON.parse(response.body)
    name = parsed["slug"]
    version = parsed["current_release"]["version"]
    moddeps = parsed["current_release"]["metadata"]["dependencies"]

    return name, version, moddeps
  end
end

def processModules(name, version, moddeps)
  # Is the module decommissioned?
  if version == '999.999.999' then
    $decom.push(name)
  else
    $mods[name] = version
  end
  unless moddeps.empty?
    moddeps.each do |dep|
      $deps.push(dep) unless $deps.include? dep
    end
  end
end

# Read modules from the mod_list file and query forge API for data
file_in = File.open(mod_list, "r") do |fh|
  fh.each_line do |mod|
    mod.chomp!
    mod.gsub!(/\//,'-')
    # Method will retusn nil if mod not found
    name, version, moddeps = findModuleData(mod)
    if name then
      processModules(name, version, moddeps)
    else
      $not_found.push(mod)
    end
  end
end

# Look for dependencies
unless $deps.empty?
  $deps.each do |dep|
    # Dependencies are returned with a slash, yay for consistency
    mod = dep["name"].gsub!(/\//, "-")
    name, version, moddeps = findModuleData(mod)
    if name then
      processModules(name, version, moddeps)
    else
      $not_found.push(mod)
    end
  end
end

# return the data found
if $mods.empty?
  puts "File #{puppetfile} not generated. No active modules were found on the Forge"
else
  file_out = File.open(puppetfile, "w") do |fh|
    $mods.each do |mod,ver|
      # Forgeapi uses dashes, r10k requires slashes
      name = mod.gsub(/-/, '/')
      fh.puts "mod '#{name}', '#{ver}'"
    end
  end

  puts "File #{puppetfile} generated."

  # Clean exit
  if $not_found.empty? && $decom.empty? then
    puts "All modules found"
    exit 0
  end
end

# Errors found
if ! $not_found.empty? then
  puts "Modules not found: #{$not_found}"
end
if ! $decom.empty? then
  puts "Modules decommissioned: #{$decom}"
end

exit 2
