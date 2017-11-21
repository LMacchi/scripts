#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'optparse'

class TrustedFact
  attr_accessor :cert, :name, :value

  def initialize
    @cert  = ''
    @name  = ''
    @value = ''
  end
end

def parse_opts
  options = {}
  help = OptionParser.new do |opts|
    opts.banner = "Usage: #{$0}"
    opts.on('-c ^.puppetlabs.vm$', '--certnames ^.puppetlabs.vm$', 'Pattern to filter certnames') do |c|
      options[:cert] = c
    end
    opts.on('-f pp_role', '--fact pp_role', 'Trusted fact name') do |f|
      options[:fact] = f
    end
    opts.on('-v master', '--value master', 'Trusted fact value') do |v|
      options[:value] = v
    end
    opts.on('-h', '--help', 'Display this help') do
      puts opts
      exit
    end
  end
  help.parse!
  return options, help
end

def build_query
  "/opt/puppetlabs/bin/puppet-query \'facts { name = \"trusted\" }\'"
end

def build_query_certs(certs)
  "/opt/puppetlabs/bin/puppet-query \'facts { name = \"trusted\" and certname ~ \"#{certs}\" }\'"
end

def run_query(query)
  JSON.load `#{query}`
end

def load_facts(results)
  facts = []
  results.each do |r|
    r['value']['extensions'].each do |k,v|
      f = TrustedFact.new
      f.cert = r['certname']
      f.name = k
      f.value = v
      facts.push f
    end
  end
  facts
end

def filter_facts(facts, fact, value)
  facts.select { |f| f.name.match?(/#{fact}/) and f.value.match?(/#{value}/) }
end

options, help = parse_opts()
query = options[:cert].nil? ? build_query : build_query_certs(options[:cert])
facts = load_facts(run_query(query))
filtered = filter_facts(facts, options[:fact], options[:value])

filtered.each do |f|
  puts f.cert
end
