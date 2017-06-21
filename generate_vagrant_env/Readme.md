## Generate Vagrant Environment
Script that generates:
- Vagrantfile
- site.pp

In order to test a module under development.

Usage: ./gen_files.rb
    -m, --mod_dir [/path/to/module]  Required: Path to module containing under development. Ex: ~/my_modules/apache
    -b, --box [vagrant_box]          Required: Vagrant box title. Ex: puppetlabs/centos-7.2-64-puppet
    -v [vagrant_box_version],        Optional: Vagrant box version. Ex: 1.0.1
        --box_ver
    -u, --box_url [vagrant_box_url]  Optional: Vagrant box url. Ex: https://vagrantcloud.com/puppetlabs/boxes/centos-7.2-64-puppet
    -d, --disk [vagrantboxurl]       Optional: Secondary disk name. Ex: rhelSecondDisk.vdi
    -n, --node_name [node_name]      Optional: Name for the node to be created. Ex: test.puppetlabs.vm
    -p, --puppet [puppet_version]    Optional: Puppet Enterprise version installed in the node. Ex: 2016.4.5. Default is 3
    -h, --help                       Display this help

Once the files have been generated:

- Run `vagrant up`
- Wait for box to be provisioned
- Puppet will run and apply the module

```
==> rhel: Running Puppet with environment production...
==> rhel: Info: Loading facts
==> rhel: Info: Loading facts
==> rhel: Info: Loading facts
==> rhel: Info: Loading facts
==> rhel: Notice: Compiled catalog for node_name in environment production in 0.17 seconds
==> rhel: Info: Applying configuration version '1498066369'
==> rhel: Notice: This is the class new
==> rhel: Notice: /Stage[main]/New/Notify[This is the class new]/message: defined 'message' as 'This is the class new'
==> rhel: Notice: Applied catalog in 0.01 seconds
```

If there are errors, you modify your module directory in your workstation, save changes and run Puppet again:

```
★ lmacchi@Titere 11:32:42 ~> vagrant provision --provision-with puppet
==> rhel: Running provisioner: puppet...
==> rhel: Running Puppet with environment production...
```

Once you're done testing, destroy the vm:
- vagrant destroy -f
