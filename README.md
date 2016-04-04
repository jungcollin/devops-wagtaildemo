Infrastructure setup of [Sdvdev.com](http://sdvdev.com)
===========================================================

`chef_files` folder
-----------------
This folder contains all chef files, in this place we can:
 - Developing cookbooks and recipes
 - Interacting with nodes, such as performing a bootstrap operation

Required:
--------
 - ChefDK
 - knife-solo: `chef gem install knife-solo`
 - knife-solo_data_bag: `chef gem install knife-solo_data_bag`

#### Install ChefDK
```
$ curl -LO https://www.chef.io/chef/install.sh && sudo bash ./install.sh -P chefdk -v 0.7.0 && rm install.sh
```

#### Install `knife-solo` & `knife-solo_data_bag`
```
# install to global gems
sudo chef gem install knife-solo knife-solo_data_bag --no-user-install
```

How it works?
-------------

## To up a lightweight standalone instance
**NOTE**: lightweight instance with running sqlite2 is quite slow when getting to complex queries, it's recommend to use local instance

This require checkout the site source code at the same place which stored the `devops` folder
Expected project layout:
```
    [/]
     - [sdvdev]      # site source code
     - [devops]        # this repository
```

    # in `vagrant` folder
    $ vagrant up lightweight

    # in `chef_files` folder
    $ knife solo cook vagrant@33.33.33.33 nodes/local/lightweight.standalone.json -E development

    # in `vagrant` folder
    $ vagrant ssh lightweight

    # in lightweight instance
    (.env) vagrant@lightweight:~/sdvdev$ make init_db

    # for now the lightweight instance had firewall policy and block all income/outcome requests
    # below is adhoc to access the django application
    (.env) vagrant@lightweight:~/sdvdev$ sudo ufw disable

    # start Django application
    (.env) vagrant@lightweight:~/sdvdev$ make

    # access to the dev server with url http://33.33.33.33:8080

## To up a local standalone instance
**NOTE**: local instance runs with postgresql to improve application speed

    # in `vagrant` folder
    $ vagrant up local

    # in `chef_files` folder
    $ knife solo cook vagrant@22.22.22.22 nodes/local/local.standalone.json

    # in `vagrant` folder
    $ vagrant ssh local

    # or new vagrant instance can access via SSH
    $ ssh vagrant@22.22.22.22

    # in local instance
    (.env) vagrant@local:~/sdvdev$ make init_db

    # for now the local instance had firewall policy and block all income/outcome requests
    # below is adhoc to access the django application
    (.env) vagrant@local:~/sdvdev$ sudo ufw disable

    # start Django application
    (.env) vagrant@local:~/sdvdev$ make

    # access to the dev server with url http://22.22.22.22:8080
