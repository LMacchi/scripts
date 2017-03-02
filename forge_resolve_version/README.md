Script created to resolve latest version of forge modules and their
dependencies using forge API.
It notifies on not found and/or decommissioned modules.

Limitations: 
- Input file needs to be a list of modules
- Might not resolve all dependencies since the script is not
recursive

Usage: forge_resolve_version.rb -i /path/to/modules/list.txt [-o /path/to/Puppetfile]

Sample list.txt provided
