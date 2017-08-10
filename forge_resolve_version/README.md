Script created to resolve latest version of forge modules and their
dependencies using forge API.
It notifies on not found and/or decommissioned modules.

Limitations: 
- It only resolves Forge versions, cannot read git modules
- It retrieves latest version and assign it to each modules,
so dependencies with specific versions won't be matched
- Lines not matching a module might end up out of order

Usage: forge_resolve_version.rb -i /path/to/original/Puppetfile [-o /path/to/new/Puppetfile]

```
[root@agent1 ~]# ./forge_resolve_version.rb -i Puppetfile -o new_pf
Processing module saz-ssh
Processing module puppetlabs-stdlib
Processing module puppetlabs-concat
Processing module puppetlabs-apache
Processing module puppetlabs-mysql
Processing module puppet-staging
Processing module puppet-staging
Processing module blah-bleh
Processing module wdijkerman-zabbix
Warning: blah-bleh was not found
Warning: wdijkerman-zabbix is deprecated
```
