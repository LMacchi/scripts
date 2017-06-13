#!/opt/puppetlabs/puppet/bin/ruby
# Shamelessly stolen from
# https://github.com/dylanratcliffe/onceover
require 'r10k/puppetfile'
require 'r10k'
require 'erb'

symlinks = []
forge_modules = []
repositories = []

puppetfile = R10K::Puppetfile.new('/root/my-control-repo')
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
        'repo' => mod.instance_variable_get(:@remote),
        'ref' => mod.version
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
