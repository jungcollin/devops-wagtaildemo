#
# Cookbook Name:: varnish-setup
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

data_bag = data_bag_item("app", node["data_bag_id"])
data_bag_varnish_setup = data_bag["varnish-setup"]

# Merge the attributes of alternative cookbook `varnish-setup`
node.set["varnish-setup"] = Chef::Mixin::DeepMerge.merge(node.default["varnish-setup"], data_bag_varnish_setup)

apt_repository "varnish-cache" do
    uri "https://repo.varnish-cache.org/#{node['platform']}/"
    distribution node["lsb"]["codename"]
    components ["varnish-#{node['varnish-setup']['version']}"]
    key "https://repo.varnish-cache.org/GPG-key.txt"
    deb_src true
    notifies :nothing, "execute[apt-get update]", :immediately
end

package "varnish"

template "/etc/default/varnish" do source "varnish.erb" end
template "/etc/varnish/default.vcl" do source "default.vcl.erb" end

service "varnish" do action [:enable, :restart] end
