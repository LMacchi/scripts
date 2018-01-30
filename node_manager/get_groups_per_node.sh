#!/opt/puppetlabs/puppet/bin/ruby
# Stolen from WhatsARanjit
require 'puppet'

Puppet.initialize_settings
require File.join(Puppet['plugindest'], 'puppet', 'util', 'nc_https.rb')

nodename = ARGV[0]
raise ArgumentError, 'Please supply a nodename' unless nodename

classifier = Puppet::Util::Nc_https.new
raw        = classifier.get_classified(nodename)

# Using T/P to collect group instances
Puppet::Type.type(:node_group)
Puppet::Type::Node_group::ProviderHttps.instances

# Translating IDs to names
groups = raw['groups'].collect do |group|
  gindex = Puppet::Type::Node_group::ProviderHttps.get_name_index_from_id(group)
  $ngs[gindex]['name']
end

puts groups.sort
