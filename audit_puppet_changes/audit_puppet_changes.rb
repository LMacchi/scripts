#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'optparse'
require 'pathname'
require 'puppet'
require 'puppetdb'

class PuppetResource

  attr_accessor :type, :title, :status, :timestamp, :new_value, :old_value, :class

  def initialize
    @type       = ''
    @title      = ''
    @status     = ''
    @timestamp  = ''
    @new_value  = ''
    @old_value  = ''
    @class      = ''
  end

end

# Methods needed to get args and pretty print the objects
def parseOptions()
  # Get arguments from CLI
  options = {}
  help = OptionParser.new do |opts|
    opts.banner = "Usage: #{$0}"
    opts.on('-c certname', '--certname certname', 'Puppet node certname') do |c|
      options[:certname] = c
    end
    opts.on('-o /path/to/result/dir', '--outdir /path/to/result/dir', 'Optional: Path where to store resulting file. Default: /tmp') do |o|
      options[:outdir] = o
    end
    opts.on('-h', '--help', 'Display this help') do
      puts opts
      exit
    end
  end
  help.parse!
  return options, help
end

def validateOptions(options, help)
  # Validate arguments
  certname = options[:certname]

  if ! options[:outdir].nil?
    outdir  = Pathname.new(options[:outdir])
  else
    outdir = Pathname.new('/tmp')
  end

  unless certname
    puts "ERROR: certname is a mandatory argument"
    puts help
    exit 2
  end

  unless outdir
    puts "ERROR: #{outdir.to_s} does not exist"
    puts help
    exit 2
  end

  unless outdir.directory?
    puts "ERROR: #{outdir} is not a directory"
    puts help
    exit 2
  end

  return certname, outdir
end

def formatTime(time)
  time.strftime('%Y-%m-%d %H:%M:%S')
end

def getTimePeriod
  start  = Time.now.utc
  finish = (start - (6 * 60 * 60))

  s = formatTime(start)
  e = formatTime(finish)

  "(start_time <= \"#{s}\" and end_time >= \"#{e}\")"
end

# Accepts a certname
# Returns a json object with result
def getResult(certname)
  Puppet.initialize_settings

  # Assume monolithic
  client = PuppetDB::Client.new({
    :server => "https://#{Puppet.settings[:certname]}:8081",
    :pem    => {
        'key'     => Puppet.settings[:hostprivkey],
        'cert'    => Puppet.settings[:hostcert],
        'ca_file' => Puppet.settings[:localcacert]
    }})

  query = "reports[resource_events] { certname = \"#{certname}\" and #{getTimePeriod} } "

  response = client.request('', query)

  response.data
end

# Accepts a report
# Returns an array of resources
def parseReport(report)
  resources = []
  unless report['resource_events']['data'].nil?
    resources = report['resource_events']['data'].collect do |d|
      processResources(d)
    end
  end
  resources
end


# Accept a resource
# Returns a PuppetResource object
def processResources(resource)
  o = PuppetResource.new
  o.type       = resource['resource_type']
  o.title      = resource['resource_title']
  o.status     = resource['status']
  o.timestamp  = resource['timestamp']
  o.new_value  = resource['new_value']
  o.old_value  = resource['old_value']
  o.class      = resource['containing_class']

  o
end

def writeFile(output, outdir, certname)
  file_name = "#{certname}-#{Time.now.to_i}.txt"
  res_file = outdir + file_name
  file_out = File.open(res_file, 'w') do |fh|
    fh.puts "Report for node #{certname}"
    output.each do |o|
      time = formatTime(Time.parse(o.timestamp))

      fh.puts "#{time} - #{o.status}: #{o.type}['#{o.title}'] in class #{o.class} changed from \"#{o.old_value}\" to \"#{o.new_value}\""
    end
  end
end

options, help = parseOptions()
certname, outdir = validateOptions(options, help)

reports = getResult(certname)

all_resources = []
reports.each do |report|
  parseReport(report).each do |p|
    all_resources << p
  end
end

# Final has a list of all PuppetResource objects
# Time to save to disk
writeFile(all_resources, outdir, certname)

exit 0
