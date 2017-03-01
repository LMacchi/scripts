This script reads the console variables from each node 
using the rake API and returns node_group definitions
using puppet code. Just save the output and puppet
apply it to a PE 3.8/4+ master.

Usage: migrate_vars.rb /path/to/nodes/list.txt

Sample nodes.txt and output provided

Requirements: Module WhatsARanjit/node_manager installed
