#!/opt/puppetlabs/puppet/bin/ruby

require 'net/https'
require 'uri'
require 'json'
require 'optparse'
require 'puppet'
require 'r10k/puppetfile'

Puppet.initialize_settings

class CmdOptions
  attr_reader :input, :output

  def initialize
    options = parse_options
    @input  = options[:input]
    @output = options[:output]
  end

  private

  def parse_options
    options = {
      :input  => "#{Puppet.settings['environmentpath']}/#{Puppet.settings['environment']}/Puppetfile",
      :output => 'newPuppetfile',
    }
    o = OptionParser.new do |opts|
      opts.banner = "Usage: #{$0}"
      opts.on('-i FILE', '--input FILE', 'Path to original Puppetfile') do |i|
        options[:input] = i
      end
      opts.on('-o FILE', '--output FILE', 'Path to new and improved Puppetfile') do |o|
        options[:output] = o
      end
      opts.on('-h', '--help', 'Display this help') do
        puts opts
        exit
      end
    end
    o.parse!
    options
  end
end

class ControlRepo

  attr_reader :modules, :mlist, :gitmods

  def initialize(path)
    puppetfile = R10K::Puppetfile.new(File.dirname(path))
    puppetfile.load!
    @modules   = puppetfile.modules
    @gitmods   = Array.new
    @mlist     = modules_list
  end

  def cycle_through_modules(list)
    forge_data = Hash.new
    threads    = []

    list.each do |mod|
      threads << Thread.new do
        puts "Processing module '#{mod['owner']}-#{mod['name']}'..."
        res = forge_call(mod['owner'], mod['name'])

        if res.code == '200'
          data = JSON.parse(res.body)
          forge_data[data['slug']] = {
            'version' => data['current_release']['version'],
            'deps'    => data['current_release']['metadata']['dependencies'],
          }
          puts "New version: #{data['slug']}-#{data['current_release']['version']}!"
        end
      end
    end
    threads.each { |t| t.join }
    forge_data
  end

  def add_forge_deps(f)
  # Don't queue up any new deps from Forge that are
  # already in the module list.
    _f = f.map { |mod, data| { 'owner' => mod.split('-')[0], 'name' => mod.split('-')[1], } }
    check_list(_f, @mlist).flatten.each do |m|
      f[m['name']] = {
        'owner' => m['owner'],
      }
    end
    f
  end

  def gitmod_args
    @gitmods.map do |m|
      content = "mod '#{m.name}',\n"
      content += m.instance_variable_get("@args").map { |k,v| "  :#{k} => '#{v}'" }.join(",\n")
    end
  end

  def write_puppetfile(target, list)
    content  = "# Forge modules\n"
    content += list.map { |k,v| "mod '#{k}', '#{v['version']}'" }.join("\n")
    content += "\n\n# Git modules\n"
    content += gitmod_args.join("\n")
    begin
      File.open(target, 'w') { |f| f.write(content) }
    rescue e
      fail("Unable to write #{target}: #{e.message}!")
    end
  end

  private

  def modules_list
    list     = Array.new
    dep_list = Array.new

    @modules.each_entry do |m|
      if m.owner
        list << {
          'owner'   => m.owner,
          'name'    => m.name,
          'version' => m.version,
        }
        puts "Found module '#{m.owner}-#{m.name} v#{m.version}..."
      end
      if m.is_a?(R10K::Module::Forge)
        dep = m.metadata.dependencies.map do |m|
          _m    = m['name'].split('/')
          owner = _m[0]
          name  = _m[1]
          {
            'owner'   => owner,
            'name'    => name,
            'version' => nil,
          }
        end
        dep_list << dep
        dep_list.flatten!
      else
        @gitmods << m
      end
    end
    # Pulls deps for all modules, then uniqes it down
    # to one list.  Checks to see that modules are
    # not already in the list.
    list << check_list(dep_list.uniq, list)
    list.flatten!
  end

  def check_list(deps, list)
    deps.map do |m|
      if list.select { |x| x['owner'] == m['owner'] && x['name'] == m['name']}.empty?
        puts "Found dependency '#{m['owner']}-#{m['name']}'..."
        m
      end
    end.compact
  end

  def forge_call(owner, mod)
    url              = "https://forgeapi.puppet.com:443/v3/modules/#{owner}-#{mod}"
    uri              = URI.parse(url)
    http             = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl     = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    req              = Net::HTTP::Get.new(uri.request_uri, {'User-Agent' => 'test'})
    res              = http.request(req)
  end
end

opts        = CmdOptions.new
controlrepo = ControlRepo.new(opts.input)
forge_data  = controlrepo.cycle_through_modules(controlrepo.mlist)
f_data_deps = controlrepo.add_forge_deps(forge_data)

controlrepo.write_puppetfile(opts.output, f_data_deps)
