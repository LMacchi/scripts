#!/opt/puppetlabs/puppet/bin/ruby

require "net/https"
require "uri"
require "json"
require 'optparse'

# Methods
def findModuleData(mod)
  puts "Processing module #{mod}"
  url = "https://forgeapi.puppet.com:443/v3/modules/#{mod}"
  uri = URI.parse(url)

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Get.new(uri.request_uri, {'User-Agent' => 'test'})

  response = http.request(request)

  if response.code == '200'
    puts "Module #{mod} found, processing info..."
    parsed = JSON.parse(response.body)
    name = parsed["slug"]
    version = parsed["current_release"]["version"]
    moddeps = parsed["current_release"]["metadata"]["dependencies"]

    return name, version, moddeps
  else
    puts "Module #{mod} not found"
  end
end

def processModules(name, version, moddeps)
  # Is the module decommissioned?
  if version == '999.999.999' then
    puts "Module #{name} has been decommissioned"
    $decom.push(name)
  else
    $mods[name] = version
    unless moddeps.empty?
      moddeps.each do |dep|
        $deps.push(dep) unless $deps.include? dep
      end
    end
  end
end

# Get arguments from CLI
options = {}
o = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0}"
  opts.on('-i [/path/to/original/Puppetfile]', '--input [/path/to/original/Puppetfile', "Path to original Puppetfile") do |i|
    options[:input] = i
  end
  opts.on('-o [/path/to/new/Puppetfile]', '--output [/path/to/new/Puppetfile]', "Path to new and improved Puppetfile") do |o|
    options[:output] = o
  end
  opts.on('-h', '--help', 'Display this help') do
    puts opts
   $opts = opts
    exit
  end
end

o.parse!

# Validate arguments
input = options[:input]
output = options[:output] || 'Puppetfile'
outdir = File.dirname(output)


unless input
  puts "ERROR: input is a mandatory argument"
  puts o
  exit 2
end

unless File.file?(input)
  puts "ERROR: #{input} does not exist"
  puts o
  exit 2
end

unless File.directory?(outdir)
  puts "ERROR: #{outdir} does not exist"
  puts o
  exit 2
end

# Set variables
$not_found = Array.new()
$decom = Array.new()
$deps = Array.new()
$mods = Hash.new()
$mods_read = Array.new()

# Read modules from Puppetfile
file_in = File.open(input, "r") do |fh|
  fh.each_line do |line|
    line.chomp!
    if line =~ /^\s*mod\s+('|")(\w+\/\w+)('|")/ then
      $mods_read.push($2)
    end
  end
end

# Search retrieved modules
$mods_read.each do |mod|
  mod.gsub!(/\//,'-')
  # Method will retusn nil if mod not found
  name, version, moddeps = findModuleData(mod)
  if name then
    processModules(name, version, moddeps)
  else
    $not_found.push(mod)
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
  puts "File #{output} not generated. No active modules were found on the Forge"
else
  file_out = File.open(output, "w") do |fh|
    $mods.each do |mod,ver|
      # Forgeapi uses dashes, r10k requires slashes
      name = mod.gsub(/-/, '/')
      fh.puts "mod '#{name}', '#{ver}'"
    end
  end

  puts "File #{output} generated."

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
