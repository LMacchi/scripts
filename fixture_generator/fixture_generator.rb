#!/opt/puppetlabs/puppet/bin/ruby
# Shamelessly stolen from
# https://github.com/dylanratcliffe/onceover
require 'r10k/puppetfile'
require 'yaml'
require 'erb'
require 'optparse'

# Get arguments from CLI
options = {}
o = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0}"
  opts.on('-d', '--debug', 'Display debug messages') do
    options[:debug] = true
  end
  opts.on('-p [/path/to/module]', '--path [/path/to/module]', "Path to module containing Puppetfile") do |o|
    options[:path] = o
  end
  opts.on('-o [/path/to/new/fixtures.yml]', '--outfile [/path/to/new/fixtures.yml]', "Path to new fixtures.yml. Defaults to module/.fixtures.yml") do |o|
    options[:outfile] = o
  end
  opts.on('-f', '--force', 'Force overwrite of fixtures.yml file') do |o|
    options[:force] = o
  end
  opts.on('-h', '--help', 'Display this help') do
    puts opts
    $opts = opts
    exit 0 
  end
end

o.parse!

control_repo = options[:path]
puppetfile = File.expand_path('./Puppetfile', control_repo)
environment_conf = File.expand_path('./environment.conf', control_repo)
fixtures_file = File.expand_path('.fixtures.yml', control_repo)
outfile = options[:output] || "#{control_repo}/.fixtures.yml"

# Validate Args
unless control_repo
  puts "ERROR: path is a mandatory argument"
  puts o
  exit 2
end

unless File.directory?(control_repo)
  puts "ERROR: #{control_repo} does not exist"
  puts o
  exit 2
end

unless File.exists?(puppetfile)
  puts "ERROR: Puppetfile does not exist in #{control_repo}"
  exit 2
end

if File.exists?(fixtures_file) and !options[:force]
  puts "ERROR: #{fixtures_file} already exists. Remove, use outfile argument or force."
  puts o
  exit 2
end

symlinks = []
forge_modules = []
repositories = []

puppetfile = R10K::Puppetfile.new(control_repo)
puppetfile.load!

modules = puppetfile.modules
modules.each do |mod|
  puts "DEBUG: Processing #{mod.name}" if options[:debug]
  # This logic could probably be cleaned up. A lot.
  if mod.is_a? R10K::Module::Forge
    if mod.expected_version.is_a?(Hash)
      # Set it up as a symlink, because we are using local files in the Puppetfile
      symlinks << {
        'name' => mod.name,
        'dir' => mod.expected_version[:path]
      }
    elsif mod.expected_version.is_a?(String)
      # Set it up as a normal firge module
      forge_modules << {
        'name' => mod.name,
        'repo' => mod.title,
        'ref' => mod.expected_version
      }
    end
  elsif mod.is_a? R10K::Module::Git
    # Set it up as a git repo
    repositories << {
        'name' => mod.name,
        # I know I shouldn't be doing this, but trust me, there are no methods
        # anywhere that expose this value, I looked.
        'repo' => mod.instance_variable_get(:@remote),
        'ref' => mod.version
      }
  end
end

# Add modules linked in environment.conf
if File.exists?(environment_conf)
  env_conf = File.read(environment_conf)
  env_conf = env_conf.split("\n")

  # Delete commented out lines
  env_conf.delete_if { |l| l =~ /^\s*#/}

  # Map the lines into a hash
  environment_config = {}
  env_conf.each do |line|
    environment_config.merge!(Hash[*line.split('=').map { |s| s.strip}])
  end

  # Finally, check if there are special modules inside the control-repo
  # If so, split the modulepath values and return a symlink
  if environment_config['modulepath']
    environment_config['modulepath'] = environment_config['modulepath'].split(':')
  
    code_dirs = environment_config['modulepath']
    code_dirs.delete_if { |dir| dir[0] == '$'}
    code_dirs.each do |dir|
      # We need to traverse down into these directories and create a symlink for each
      # module we find because fixtures.yml is expecting the module's root not the
      # root of modulepath
      Dir["#{control_repo}/#{dir}/*"].each do |mod|
        symlinks << {
          'name' => File.basename(mod),
          'dir' => '"#{source_dir}/' + "#{dir}/#{File.basename(mod)}\""
        }
      end
    end
  end
end

template = %q(
---
fixtures:
<% if symlinks.any? then -%>
  symlinks:
<% symlinks.each do |link| -%>
    <%= link['name'] %>: <%= link['dir'] %>
<% end -%>
<% end -%>
<% if repositories.any? then -%>
  repositories:
<% repositories.each do |repo| -%>
    <%= repo['name'] %>:
      repo: <%= repo['repo'] %>
      ref: <%= repo['ref'] %>
<% end -%>
<% end -%>
<% if forge_modules.any? then -%>
  forge_modules:
<% forge_modules.each do |mod| -%>
    <%= mod['name'] %>:
      repo: <%= mod['repo'] %>
      ref: <%= mod['ref'] %>
<% end -%>
<% end -%>
)

file_out = File.open(outfile, "w") do |fh|
  fh.puts ERB.new(template, nil, '-').result(binding)
end
