Script created to resolve latest version of forge modules and their
dependencies using forge API.
It notifies on not found and/or decommissioned modules.

Limitations: 
- Might not resolve all dependencies since the script is not
recursive
- It retrieves latest version and assign it to each modules,
so specific dependencies versions will not work

Usage: forge_resolve_version.rb -i /path/to/original/Puppetfile [-o /path/to/new/Puppetfile]

```
[root@agent1 ~]# ./forge_resolve_version.rb -i Puppetfile -o new_pf
Processing module saz-ssh
Module saz-ssh found, processing info...
Processing module puppetlabs-apache
Module puppetlabs-apache found, processing info...
Processing module puppetlabs-mysql
Module puppetlabs-mysql found, processing info...
Processing module puppet-staging
Module puppet-staging found, processing info...
Processing module blah-bleh
Module blah-bleh not found
Processing module wdijkerman-zabbix
Module wdijkerman-zabbix found, processing info...
Module wdijkerman-zabbix has been decommissioned
Processing module puppetlabs-stdlib
Module puppetlabs-stdlib found, processing info...
Processing module puppetlabs-concat
Module puppetlabs-concat found, processing info...
Processing module puppetlabs-stdlib
Module puppetlabs-stdlib found, processing info...
Processing module puppetlabs-concat
Module puppetlabs-concat found, processing info...
Processing module puppetlabs-stdlib
Module puppetlabs-stdlib found, processing info...
Processing module puppet-staging
Module puppet-staging found, processing info...
Processing module puppetlabs-stdlib
Module puppetlabs-stdlib found, processing info...
File new_pf generated.
Modules not found: ["blah-bleh"]
Modules decommissioned: ["wdijkerman-zabbix"]
```
