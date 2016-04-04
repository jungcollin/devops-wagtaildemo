#
# Cookbook Name:: postgresql-setup
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

data_bag = data_bag_item("app", node["data_bag_id"])
data_bag_postgresql = data_bag["postgresql"]
app_servers = data_bag["app_servers"]

# Merge the attributes of alternative cookbook `postgresql`
node.set["postgresql"] = Chef::Mixin::DeepMerge.merge(node.default["postgresql"], data_bag_postgresql)

# ref: https://github.com/CultivateLabs/rails-fed-chef/tree/master/site-cookbooks/postgres-setup
apt_repository "apt.postgresql.org" do
    uri "http://apt.postgresql.org/pub/repos/apt"
    distribution "#{node["lsb"]["codename"]}-pgdg"
    components ["main"]
    key "http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc"
    action :add
end

# ref: http://vladigleba.com/blog/2014/08/12/provisioning-a-rails-server-using-chef-part-2-writing-the-recipes/
package "postgresql-#{node["postgresql"]["version"]}"
package "libpq-dev"

template "/etc/postgresql/#{node["postgresql"]["version"]}/main/pg_hba.conf" do
    source "pg_hba.conf.erb"
    owner "postgres"
    group "postgres"
    mode 00600
end

template "/etc/postgresql/#{node["postgresql"]["version"]}/main/postgresql.conf" do
    source "postgresql.conf.erb"
    owner "postgres"
    group "postgres"
    mode 00600
end

# change postgres password
execute "change postgres password" do
    user "postgres"
    command "psql -c \"alter user postgres with password '#{node["postgresql"]["password"]}';\""
end

# create new postgres user
execute "create new postgres user" do
    user "postgres"
    command "psql -c \"create user #{node["postgresql"]["user"]["name"]} with password '#{node["postgresql"]["user"]["password"]}';\""
    not_if { `sudo -u postgres psql -tAc \"SELECT * FROM pg_roles WHERE rolname='#{node["postgresql"]["user"]["name"]}'\" | wc -l`.chomp == "1" }
end

# create new postgres databases
execute "create new postgres database" do
    user "postgres"
    command "psql -c \"create database #{node["postgresql"]["user"]["database"]} owner #{node["postgresql"]["user"]["name"]};\""
    not_if { `sudo -u postgres psql -tAc \"SELECT * FROM pg_database WHERE datname='#{node["postgresql"]["user"]["database"]}'\" | wc -l`.chomp == "1" }
end

service "postgresql" do action [:enable, :restart] end

# firewall policy for accessing postgresql database
app_servers.each do |server|
    firewall_rule "postgres" do
        port      5432
        source    "#{server}"
        command   :allow
    end
end
