## API Abstraction Script

This script abstracts the use of Puppet APIs. Passing some arguments through command line, it contacts different Puppet APIs.

## Usage

To get AD integration settings:

```
[root@10-32-175-155 scripts]# ./api_abstraction.rb -a rbac -e ds -m get | python -m json.tool
{
    "base_dn": null,
    "connect_timeout": null,
    "disable_ldap_matching_rule_in_chain": false,
    "display_name": null,
    "group_lookup_attr": null,
    "group_member_attr": null,
    "group_name_attr": null,
    "group_object_class": null,
    "group_rdn": null,
    "help_link": null,
    "hostname": null,
    "login": null,
    "password": null,
    "port": null,
    "search_nested_groups": true,
    "ssl": null,
    "start_tls": null,
    "type": null,
    "user_display_name_attr": null,
    "user_email_attr": null,
    "user_lookup_attr": null,
    "user_rdn": null
}
```

To create a RBAC role:
```
[root@10-32-175-155 scripts]# ./api_abstraction.rb -a rbac -e roles -m post -j data.json
Response 303
[root@10-32-175-155 scripts]# ./api_abstraction.rb -a rbac -e roles -m get | python -mjson.tool
[
    {
        "description": "Test User",
        "display_name": "test_user",
        "group_ids": [],
        "id": 6,
        "permissions": [
            {
                "action": "view_data",
                "instance": "*",
                "object_type": "nodes"
            }
        ],
        "user_ids": []
    }
]
```
