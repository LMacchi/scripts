#!/opt/puppetlabs/puppet/bin/ruby
require 'puppet'

Puppet.initialize_settings
require File.join(Puppet['plugindest'], 'puppet', 'util', 'nc_https.rb')

nodename = ARGV[0]
raise ArgumentError, 'Please supply a nodename' unless nodename

classifier = Puppet::Util::Nc_https.new
raw        = classifier.get_classified(nodename)

puts raw['classes'].keys.sort
