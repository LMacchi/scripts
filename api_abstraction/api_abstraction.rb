#!/opt/puppetlabs/puppet/bin/ruby

require 'optparse'
require 'puppet'
require 'yaml'
require 'net/http'
require 'uri'
require 'json'

require File.expand_path(File.dirname(__FILE__) + '/get_puppet_urls.rb')

# Get options from command line
ARGV.push('-h') if ARGV.empty?
options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"
 opts.on('-a [activity|admin|ca|classifier|puppetdb|rbac]', '--api [activity|admin|ca|classifier|puppetdb|rbac]', "API to contact") do |a|
    options[:api] = a
  end
  opts.on('-e [ARG]', '--endpoint [ARG]', "API end point") do |e|
    options[:endpoint] = e
  end
  opts.on('-m [post|get]', '--method [post|get]', "HTTP Method") do |m|
    options[:method] = m
  end
  opts.on('-j [/path/to/data.json]', '--json_file [/path/to/data.json]', "Path to data.json file") do |j|
    options[:json_file] = j
  end
  opts.on('-h', '--help', 'Display this help') do
    puts opts
    exit
  end
end

parser.parse!

if options[:api].empty? || options[:method].empty? || options[:endpoint].empty?
  puts "api, method and endpoint are required arguments"
  exit 2
end

if options[:api]
  fail "API can only be puppetdb, classifier, activity, ca, admin, or rbac" unless ['puppetdb','classifier','rbac','activity','ca','admin'].include? options[:api]
end

if options[:json_file]
  fail "#{options[:json_file]} does not exist" unless File.file?(options[:json_file])
  $data = YAML.load_file(options[:json_file])
end

if options[:method]
  fail "Allowed methods post and get" unless ['post','get'].include? options[:method]
end

if options[:method] == 'post' && ! options[:json_file]
  puts "JSON file required when using method post"
  exit 2
end

# Get Puppet settings
Puppet.initialize_settings

certname = Puppet.settings[:certname]
hostcert = File.read(Puppet.settings[:hostcert])
hostprivkey = File.read(Puppet.settings[:hostprivkey])
localcert = Puppet.settings[:localcacert]

# Get Puppet urls
orch_file = '/etc/puppetlabs/orchestration-services/conf.d/orchestrator.conf'
puppet_url = return_urls(orch_file)

rbac_url = puppet_url['classifier'] + '/rbac-api/v1'
classifier_url = puppet_url['classifier'] + '/classifier-api/v1'
activity_url = puppet_url['classifier'] + '/activity-api/v1'
puppetdb_url = puppet_url['puppetdb'] + '/pdb/query/v4'
puppetca_url = puppet_url['master'] + '/puppet-ca/v1'
admin_url = puppet_url['master'] + '/puppet-admin/v1'

# Choose url to use
case options[:api]
when 'rbac'
  $url = rbac_url
when 'classifier'
  $url = classifier_url
when 'activity'
  $url = activity_url
when 'puppetdb'
  $url = puppetdb_url
when 'ca'
  $url = puppetca_url
when 'admin'
  $url = admin_url
end

# Prepare request
uri = URI("#{$url}/#{options[:endpoint]}")

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.cert = OpenSSL::X509::Certificate.new(hostcert)
http.key = OpenSSL::PKey::RSA.new(hostprivkey)
http.ca_file = localcert
http.verify_mode = OpenSSL::SSL::VERIFY_CLIENT_ONCE

if options[:method] == 'post'
  $request = Net::HTTP::Post.new(uri.request_uri)
  $request.body = $data.to_json
  $request.content_type = 'application/json'
elsif options[:method] == 'get'
  $request = Net::HTTP::Get.new(uri.request_uri)
else
  puts "Only methods post or get supported"
  exit 2
end

response = http.request($request)
if response.body.empty? then
  output = "Response #{response.code}"
else
  output = response.body
end

puts output
