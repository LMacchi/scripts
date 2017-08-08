#!/opt/puppetlabs/puppet/bin/ruby

require 'net/https'
require 'uri'
require 'json'
require 'optparse'
require 'puppet'


class ForgeVersions

  attr_reader :read_mods, :deps, :not_found, :decom, :lines, :modules

  def initialize
    @read_mods = Array.new
    @deps = Array.new
    @not_found = Array.new
    @decom = Array.new
    @lines = Array.new
    @modules = Hash.new
  end

  # Cannot use attr_writers for arrays/hashes
  def add_mod(mod)
    @read_mods.push(mod) unless @read_mods.include? mod
  end

  def add_dep(mod)
    @deps.push(mod) unless @deps.include? mod
  end

  def add_nf(mod)
    @not_found.push(mod) unless @not_found.include? mod
  end

  def add_decom(mod)
    @decom.push(mod) unless @decom.include? mod
  end

  def add_lines(line)
    @lines.push(line)
  end

  def add_mod_data(name, ver)
    @modules[name] = ver
  end

  def parse_options()
    # Get arguments from CLI
    options = {}
    help = OptionParser.new do |opts|
      opts.banner = "Usage: #{$0}"
      opts.on('-i [/path/to/original/Puppetfile]', '--input [/path/to/original/Puppetfile', "Path to original Puppetfile") do |i|
        options[:input] = i
      end
      opts.on('-o [/path/to/new/Puppetfile]', '--output [/path/to/new/Puppetfile]', "Path to new and improved Puppetfile") do |o|
        options[:output] = o
      end
      opts.on('-h', '--help', 'Display this help') do
        puts opts
        exit
      end
    end
    help.parse!
    return options, help
  end

  def validate_options(options, help)
    # Validate arguments
    input = options[:input]
    output = options[:output] || 'Puppetfile'
    outdir = File.dirname(output)

    unless input
      puts "ERROR: input is a mandatory argument"
      puts help
      exit 2
    end

    unless File.file?(input)
      puts "ERROR: #{input} does not exist"
      puts help
      exit 2
    end

    unless File.directory?(outdir)
      puts "ERROR: #{outdir} does not exist"
      puts help
      exit 2
    end

    return input, output, outdir
  end

  def read_puppetfile(input)
    # Read modules from Puppetfile
    file_in = File.open(input, "r") do |fh|
      fh.each_line do |line|
        line.chomp!
        if line =~ /^\s*mod\s+('|")(\w+[\/-]\w+)('|"),\s+\S+/ then
          add_mod($2)
        else
          add_lines(line)
        end
      end
    end
  end

  def search_modules(modules)
    # Search retrieved modules
    modules.each do |mod|
      _mod = mod.gsub(/\//,'-')
      # Method will return nil if mod not found
      name, version, moddeps = findModuleData(_mod)
      if name
        process_modules(name, version, moddeps)
      else
        add_nf(_mod)
      end
    end
  end

  def process_modules(name, version, moddeps)
    if version == '999.999.999'
      add_decom(name)
    else
      add_mod_data(name, version)
      if moddeps.any?
        moddeps.each do |dep|
          add_dep(dep)
        end
      end
    end
  end

  # Look for dependencies
  def search_dependencies(modules)
    modules.each do |mod|
      # Dependencies are returned with a slash, yay for consistency
      _mod = mod['name'].gsub(/\//, "-")
      name, version, moddeps = findModuleData(_mod)
      if name then
        process_modules(name, version, moddeps)
      else
        add_nf(mod)
      end
    end
  end

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

  # return the data found
  def write_response(output)
    forge = @lines.grep /^forge/i
    file_out = File.open(output, "w") do |fh|
      if forge 
        fh.puts forge.to_s + "\n"
      end
      @modules.each do |mod,ver|
        fh.puts "mod '#{mod}', '#{ver}'"
      end
      fh.puts @lines - forge
    end
  end
end

# Set variables
f = ForgeVersions.new

@modules = f.modules
@mods_read = f.read_mods
@lines = f.lines
@not_found = f.not_found
@decom = f.decom
@deps = f.deps

options, help = f.parse_options()
input, output, outdir = f.validate_options(options, help)
f.read_puppetfile(input)
# I have an array of modules and an array of lines
f.search_modules(@mods_read)
# I've found existant modules, non-existant, deprecated
# and dependencies
f.search_dependencies(@deps)

# Processing done, write to output
require 'pry'; binding.pry
if @mods_read.any? or @lines.any?
  f.write_response(output)
else
  puts "No modules found. #{output} not created"
end
# Output warnings
if @not_found.any?
  puts "WARNING: Modules not found: #{@not_found}"
end
if @decom.any?
  puts "WARNING: Modules deprecated: #{@decom}"
end


