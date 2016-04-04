#
# Cookbook Name:: load-balancer-setup
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

data_bag = data_bag_item("app", node["data_bag_id"])
data_bag_site_setup = data_bag["load-balancer-setup"]
data_bag_varnish_setup = data_bag["varnish-setup"]

node.default["load-balancer-setup"]["site_domain"] = site_domain = data_bag["site_domain"]
node.set["load-balancer-setup"] = Chef::Mixin::DeepMerge.merge(node.default["load-balancer-setup"], data_bag_site_setup)

template "#{node["nginx"]["dir"]}/sites-enabled/#{site_domain}" do
    source "load-balancer-site.conf.erb"
    notifies :restart, 'service[nginx]', :delayed
end

# restricted unauthorized access on staging environment
if node.chef_environment == "staging"
    template "#{node["nginx"]["dir"]}/.htpasswd" do
        source ".htpasswd"
        notifies :restart, 'service[nginx]', :delayed
    end
end

firewall_rule "load-balancer" do
    port      node["load-balancer-setup"]["port"]
    source    data_bag_varnish_setup["host"]
    command   :allow
end
