#!/opt/puppetlabs/puppet/bin/ruby
# Script that generates:
# - Vagrantfile
# - site.pp

require 'optparse'
require 'erb'
require 'pathname'

# Get arguments from CLI
options = {}
o = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0}"
  opts.on('-m [/path/to/module/project]', '--mod_dir [/path/to/module/project]', "Required: Path to project containing modules under development. Ex: ~/workspace/project1") do |o|
    options[:mod_dir] = o
  end
  opts.on('-b [vagrant_box]', '--box [vagrant_box]', "Required: Vagrant box title. Ex: puppetlabs/centos-7.2-64-puppet") do |o|
    options[:box] = o
  end
  opts.on('-v [vagrant_box_version]', '--box_ver [vagrant_box_version]', "Optional: Vagrant box version. Ex: 1.0.1") do |o|
    options[:box_ver] = o
  end
  opts.on('-u [vagrant_box_url]', '--box_url [vagrant_box_url]', "Optional: Vagrant box url. Ex: https://vagrantcloud.com/puppetlabs/boxes/centos-7.2-64-puppet") do |o|
    options[:box_url] = o
  end
  opts.on('-d [/path/to/disk]', '--disk [vagrantboxurl]', "Optional: Secondary disk name. Ex: rhelSecondDisk.vdi") do |o|
    options[:disk] = o
  end
  opts.on('-n [node_name]', '--node_name [node_name]', "Optional: Name for the node to be created. Ex: test.puppetlabs.vm") do |o|
    options[:node_name] = o
  end
  opts.on('-p [puppet_version]', '--puppet [puppet_version]', "Optional: Puppet Enterprise version installed in the node. Ex: 2016.4.5. Default is 4") do |o|
    options[:puppet] = o
  end
  opts.on('-s [puppet_server_host]', '--server [puppet_version]', "Optional: URL/IP of the Puppet Master server") do |o|
    options[:server] = o
  end
  opts.on('-h', '--help', 'Display this help') do
    puts opts
    exit 0 
  end
end

o.parse!

# Create vars to use
mod_dir = options[:mod_dir]
box = options[:box]
box_ver = options[:box_ver]
box_url = options[:box_url]
disk = options[:disk]
node_name = options[:node_name]
puppet = options[:puppet]
master = options[:server]

# Validate vars
puppet = '4' unless puppet

unless mod_dir
  puts "ERROR: mod_dir is a required argument"
  puts o
  exit 2
end

unless File.directory?(mod_dir)
  puts "ERROR: #{mod_dir} does not exist"
  puts o
  exit 2
end

unless box
  puts "ERROR: box is a required argument"
  puts o
  exit 2
end

# Assign internal vars
if puppet =~ /^3/
  puppet_bin = '/opt/puppet/bin'
elsif puppet =~ /^4/ || puppet =~ /^2/
  puppet_bin = '/opt/puppetlabs/puppet/bin'
end

# These values come from the Puppet provisioner in Vagrant
code_dir = '/vagrant/puppet'
global_mod_dir = '/etc/puppet/modules'

# Generate Vagrantfile
vf_template = "#{File.expand_path(File.dirname(__FILE__))}/templates/Vagrantfile.erb"
unless File.exists?(vf_template)
  puts "Vagrantfile template not found. Make sure it is in #{vf_template} to continue."
  exit 2
end

vf = File.read(vf_template)
vf_out = "#{File.expand_path(File.dirname(__FILE__))}/Vagrantfile"

file_out = File.open(vf_out, "w") do |fh|
  fh.puts ERB.new(vf, nil, '-').result()
end

# Read all directories in mod_dir
dirs = Pathname.new(mod_dir).children.select {|f| f.directory? }.collect { |p| File.basename(p.to_s) }

# Generate site.pp
site_template = "#{File.expand_path(File.dirname(__FILE__))}/templates/site.pp.erb"
unless File.exists?(site_template)
  puts "Site.pp template not found. Make sure it is in #{site_template} to continue."
  exit 2
end

site = File.read(site_template)
site_out = "#{File.expand_path(File.dirname(__FILE__))}/puppet/manifests/site.pp"

file_out = File.open(site_out, "w") do |fh|
  fh.puts ERB.new(site, nil, '-').result()
end

# Generate Puppetfile
pf_template = "#{File.expand_path(File.dirname(__FILE__))}/templates/Puppetfile.erb"
unless File.exists?(pf_template)
  puts "Puppetfile template not found. Make sure it is in #{pf_template} to continue."
  exit 2
end

pf = File.read(pf_template)
pf_out = "#{mod_dir}/Puppetfile"

file_out = File.open(pf_out, "w") do |fh|
  fh.puts ERB.new(pf, nil, '-').result()
end
