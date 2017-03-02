Script created to resolve latest version of forge modules and their
dependencies using forge API.
It returns a Puppetfile_new file in the current directory.
It notifies on not found and/or decommissioned modules.

Limitations: 
- Input file needs to be a list of modules
- Might not resolve all dependencies since the script is not
recursive

Usage: forge_resolve_version.rb /path/to/modules/list.txt

Sample list.txt provided
