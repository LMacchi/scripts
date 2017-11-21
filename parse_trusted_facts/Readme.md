## Parse Trusted Facts

Currently Puppet Query does not allow to query trusted facts, so I wrote
a script to do that.

### Requirements
Puppet-query needs to be fully set up.

### Usage

```
# ./parse_trusted_facts.rb -h
Usage: ./parse_trusted_facts.rb
    -c, --certnames ^.puppetlabs.vm$ Pattern to filter certnames
    -f, --fact pp_role               Trusted fact name
    -v, --value master               Trusted fact value
    -h, --help                       Display this help
```

```
# ./parse_trusted_facts.rb -f pp_role -v agent
10-32-175-18.rfc1918.puppetlabs.net
# ./parse_trusted_facts.rb -f pp_role -v agent -c puppetlabs.com
# ./parse_trusted_facts.rb -f pp_role -v agent -c puppetlabs.net
10-32-175-18.rfc1918.puppetlabs.net
```

- Certnames: A regular expression to limit results
- Fact: A regular expression to match the name of the trusted fact
- Value: A regular expression to match the value of the trusted fact
