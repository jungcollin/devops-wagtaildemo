deploy-setup Cookbook
=====================
TODO: Enter the cookbook description here.

e.g.
This cookbook makes your favorite breakfast sandwich.

Requirements
------------
TODO: List your cookbook requirements. Be sure to include any requirements this cookbook has on platforms, libraries, other cookbooks, packages, operating systems, etc.

e.g.
#### packages
- `toaster` - deploy-setup needs toaster to brown your bagel.

Attributes
----------
```
"deploy-setup": {
  "user" : {
    "name" : "username-here",
    "password" : "$1$SUKggaYX$ZojkelSt/Gva/XYVudCUI.",
    "group": "group-here",
    "allowed_ssh_keys" : ["your-ssh-keys-here"]
  },
  "git_repo": {
    "target_dir": "target-directory-here",
    "repository": "repository-url-here",
    "revision": "revision-specific-here"
  }
```

#### How to generate `Password Shadow Hash`
`openssl passwd -1 "theplaintextpassword"``
or `mkpasswd -m sha-512`


e.g.
#### deploy-setup::default
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['deploy-setup']['bacon']</tt></td>
    <td>Boolean</td>
    <td>whether to include bacon</td>
    <td><tt>true</tt></td>
  </tr>
</table>

Usage
-----
#### deploy-setup::default
TODO: Write usage instructions for each cookbook.

e.g.
Just include `deploy-setup` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[deploy-setup]"
  ]
}
```

Contributing
------------
TODO: (optional) If this is a public cookbook, detail the process for contributing. If this is a private cookbook, remove this section.

e.g.
1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------
Authors: TODO: List authors
