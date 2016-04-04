Workstations
------------
This folder contains all chef files, in this place we can:
 - Developing cookbooks and recipes
 - Interacting with nodes, such as performing a bootstrap operation
 - More detail: from [docs.chef.io](https://docs.chef.io/workstation.html#workstations)

Required:
--------
 - ChefDK
 - knife-solo: `chef gem install knife-solo`

Folder layouts
---------------------------
 - .chef/
 - cookbooks/
 - data_bags/
 - environment/
 - nodes/
 - roles/
 - site-cookbooks/
 - Berksfile
 - Berksfile.lock

How to set environment for a node
---------------------------------
 - @ref: https://docs.chef.io/environments.html#set-for-a-node
 - "By editing the environment configuration details in the client.rb file, and then using knife bootstrap -e environment_name to bootstrap the changes to the specified environment"

How to cook a node?
------------------
 - $ knife solo cook [username]@[host_name] -E [environment]
 - e.g: $ knife solo cook vagrant@10.0.0.20 -E development

How to install a lightweight node?
----------------------------------
 - In `workstation` folder
 - $ knife solo cook vagrant@10.0.0.20 nodes/local/lightweight.standalone.json -E development

How to install a full standalone node?
--------------------------------------
 - In `workstation` folder
 - $ knife solo cook vagrant@10.0.0.21 nodes/local/local.standalone.json -E development


Common Issues:
-------------

[1]
Setup firewall is required defining `depends 'firewall'` in the metadata.rb file
