## On 3.2 Master

```
[root@master ~]# ./script.rb nodes.txt
For node git.puppetlabs.vm variable site is dfw
For node git.puppetlabs.vm variable role is vcs
For node master.puppetlabs.vm variable site is dfw
For node master.puppetlabs.vm variable role is puppetmaster
[root@master ~]# cat nodes.pp
node_group { 'dfw':
  ensure => present,
  environment => 'production',
  override_environment => false,
  parent => 'default',
  rule => ['or', ['=', 'name', 'master.puppetlabs.vm'], ['=', 'name', 'git.puppetlabs.vm']],
  variables => {'site' => 'dfw'},
}

node_group { 'puppetmaster':
  ensure => present,
  environment => 'production',
  override_environment => false,
  parent => 'default',
  rule => ['or', ['=', 'name', 'master.puppetlabs.vm']],
  variables => {'role' => 'puppetmaster'},
}

node_group { 'vcs':
  ensure => present,
  environment => 'production',
  override_environment => false,
  parent => 'default',
  rule => ['or', ['=', 'name', 'git.puppetlabs.vm']],
  variables => {'role' => 'vcs'},
}
```

## On 3.8 master

```
[root@master ~]# puppet apply nodes.pp
Notice: Compiled catalog for master.puppetlabs.vm in environment production in 0.08 seconds
Notice: /Stage[main]/Main/Node_group[dfw]/ensure: created
Notice: /Stage[main]/Main/Node_group[puppetmaster]/ensure: created
Notice: /Stage[main]/Main/Node_group[vcs]/ensure: created
Notice: Finished catalog run in 1.64 seconds
[root@master ~]# puppet resource node_group dfw
node_group { 'dfw':
  ensure               => 'present',
  environment          => 'production',
  id                   => '83a1ad5a-6aff-476c-ad20-001f475a10ee',
  override_environment => 'false',
  parent               => 'default',
  rule                 => ['or', ['=', 'name', 'master.puppetlabs.vm'], ['=', 'name', 'git.puppetlabs.vm']],
  variables            => {'site' => 'dfw'},
}
[root@master ~]# puppet resource node_group puppetmaster
node_group { 'puppetmaster':
  ensure               => 'present',
  environment          => 'production',
  id                   => 'e6a20121-aed3-467b-9457-8578961868c0',
  override_environment => 'false',
  parent               => 'default',
  rule                 => ['or', ['=', 'name', 'master.puppetlabs.vm']],
  variables            => {'role' => 'puppetmaster'},
}
[root@master ~]# puppet resource node_group vcs
node_group { 'vcs':
  ensure               => 'present',
  environment          => 'production',
  id                   => '7ebbcd81-dbf0-4e19-8c14-06bdf46f2e84',
  override_environment => 'false',
  parent               => 'default',
  rule                 => ['or', ['=', 'name', 'git.puppetlabs.vm']],
  variables            => {'role' => 'vcs'},
}
[root@master ~]#
```
