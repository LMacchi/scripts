# Audit Puppet Resources

Script that shows the resources that changed in one Puppet node in a 6 hours period.

## Requirements

This script requires the [puppetdb-ruby](https://github.com/voxpupuli/puppetdb-ruby) gem.

```
# /opt/puppetlabs/puppet/bin/gem install puppetdb-ruby
```

Script only runs in the Puppet master as root or with sudo.

## Usage

```
$ ./audit_puppet_changes.rb
ERROR: certname is a mandatory argument
Usage: ./audit_puppet_changes.rb
    -c, --certname certname          Puppet node certname
    -o, --outdir /path/to/result/dir Optional: Path where to store resulting file. Default: /tmp
    -h, --help                       Display this help
```

## Output

```
Report for node jenkins.puppetlabs.net
2018-02-28 10:48:07 - skipped: Service['jenkins'] in class Profile::Jenkins2 changed from "" to ""
2018-02-28 10:48:07 - failure: File_line['disable security in jenkins'] in class Profile::Jenkins2 changed from "" to ""
2018-02-28 10:48:06 - success: Notify['My master is puppet.puppetlabs.net'] in class Main changed from "absent" to "My master is puppet.puppetlabs.net"
2018-02-28 11:18:07 - skipped: Service['jenkins'] in class Profile::Jenkins2 changed from "" to ""
2018-02-28 11:18:07 - failure: File_line['disable security in jenkins'] in class Profile::Jenkins2 changed from "" to ""
2018-02-28 11:18:06 - success: Notify['My master is puppet.puppetlabs.net'] in class Main changed from "absent" to "My master is puppet.puppetlabs.net"
2018-02-28 11:48:07 - skipped: Service['jenkins'] in class Profile::Jenkins2 changed from "" to ""
2018-02-28 11:48:07 - failure: File_line['disable security in jenkins'] in class Profile::Jenkins2 changed from "" to ""
2018-02-28 11:48:06 - success: Notify['My master is puppet.puppetlabs.net'] in class Main changed from "absent" to "My master is puppet.puppetlabs.net"
2018-02-28 12:18:07 - skipped: Service['jenkins'] in class Profile::Jenkins2 changed from "" to ""
2018-02-28 12:18:07 - failure: File_line['disable security in jenkins'] in class Profile::Jenkins2 changed from "" to ""
2018-02-28 12:18:07 - success: Notify['My master is puppet.puppetlabs.net'] in class Main changed from "absent" to "My master is puppet.puppetlabs.net"
2018-02-28 12:48:08 - skipped: Service['jenkins'] in class Profile::Jenkins2 changed from "" to ""
2018-02-28 12:48:08 - failure: File_line['disable security in jenkins'] in class Profile::Jenkins2 changed from "" to ""
2018-02-28 12:48:07 - success: Notify['My master is puppet.puppetlabs.net'] in class Main changed from "absent" to "My master is puppet.puppetlabs.net"
2018-02-28 13:18:07 - skipped: Service['jenkins'] in class Profile::Jenkins2 changed from "" to ""
2018-02-28 13:18:07 - failure: File_line['disable security in jenkins'] in class Profile::Jenkins2 changed from "" to ""
2018-02-28 13:18:06 - success: Notify['My master is puppet.puppetlabs.net'] in class Main changed from "absent" to "My master is puppet.puppetlabs.net"
2018-02-28 13:48:07 - skipped: Service['jenkins'] in class Profile::Jenkins2 changed from "" to ""
2018-02-28 13:48:07 - failure: File_line['disable security in jenkins'] in class Profile::Jenkins2 changed from "" to ""
2018-02-28 13:48:06 - success: Notify['My master is puppet.puppetlabs.net'] in class Main changed from "absent" to "My master is puppet.puppetlabs.net"
```
