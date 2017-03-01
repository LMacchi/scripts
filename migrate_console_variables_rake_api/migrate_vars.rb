#!/opt/puppet/bin/ruby
# Script that retrieves variables from a PE 3.2 console
# and manipulates them to get node_groups definitions
# for a PE 3.8/4+ console

if ARGV.empty?
  puts "USAGE: #{$0} /path/to/nodes/list.txt"
  exit 1
end

# Use the rake API to retrieve variables per node
# Returns a hash with all variables returned per node
def getVarsPerNode(node)
  vars = `/opt/puppet/bin/rake -f /opt/puppet/share/puppet-dashboard/Rakefile RAILS_ENV=production node:variables[#{node}]`
  lines = vars.split("\n")
  $variables = Hash.new()

  lines.each do |line|
    i = line.split('=')
    var = i[0].chomp
    value = i[1].chomp
    $variables[var] = value
  end
  return $variables
end

# Takes the name of a variable (Ex: site)
# Returns a hash with all of the values for that var
# and all of the nodes that have that value assigned
def getNodesPerVar(target)
  data = $fullvars
  targets = Hash.new {|h,k| h[k] = Array.new}
  data.each do |node, var|
    var.each do |name,value|
      if name == target then
        targets[value].push(node)
      end
    end
  end
  return targets
end

nodes_list = ARGV[0]
$fullvars = Hash.new()

# Read nodes_list from disk and call the rake API
# for each node
file = File.open(nodes_list, "r") do |fh|
  fh.each_line do |node|
  node.chomp!
  $fullvars[node] = getVarsPerNode node
  end
end

# We're interested in site and role, so let's process
# only the nodes with those values
$sites = getNodesPerVar('site')
$roles = getNodesPerVar('role')

# Create a node_group definition per site with a rule
# pinning nodes to it
$sites.each do |site,nodes|
  $rule = "['or'"
  nodes.each do |node|
    $rule += ", ['=', 'name', '#{node}']"
  end
  $rule += "]"
  $nd = %Q(
node_group { '#{site}':
  ensure => present,
  environment => 'production',
  override_environment => false,
  parent => 'default',
  rule => #{$rule},
  variables => {'site' => '#{site}'},
}
)
  puts $nd
end

# Create a node_group definition per role with a rule
# pinning nodes to it
$roles.each do |role,nodes|
  $rule = "['or'"
  nodes.each do |node|
    $rule += ", ['=', 'name', '#{node}']"
  end
  $rule += "]"
  $nd = %Q(
node_group { '#{role}':
  ensure => present,
  environment => 'production',
  override_environment => false,
  parent => 'default',
  rule => #{$rule},
  variables => {'role' => '#{role}'},
}
)
  puts $nd
end

exit 0
