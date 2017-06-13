#!/opt/puppetlabs/puppet/bin/ruby
# Shamelessly stolen from
# https://github.com/dylanratcliffe/onceover
require 'r10k/puppetfile'
require 'yaml'
require 'erb'

if ARGV.length != 1
  puts "USAGE: $0 /path/to/control/repo"
  exit 2
end

control_repo = ARGV[0]
environment_conf = File.expand_path('./environment.conf', control_repo)

symlinks = []
forge_modules = []
repositories = []

puppetfile = R10K::Puppetfile.new(control_repo)
puppetfile.load!

modules = puppetfile.modules
modules.each do |mod|
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
        #'repo' => mod.instance_variable_get(:@remote),
        'ref' => mod.version
      }
  end
end

# Add modules linked in environment.conf
env_conf = File.read(environment_conf)
env_conf = env_conf.split("\n")

# Delete commented out lines
env_conf.delete_if { |l| l =~ /^\s*#/}

# Map the lines into a hash
environment_config = {}
env_conf.each do |line|
  environment_config.merge!(Hash[*line.split('=').map { |s| s.strip}])
end

# Finally, split the modulepath values and return
begin
  environment_config['modulepath'] = environment_config['modulepath'].split(':')
rescue
  raise "modulepath was not found in environment.conf, don't know where to look for roles & profiles"
end

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

puts ERB.new(template, nil, '-').result(binding)
