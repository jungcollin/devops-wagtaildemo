#
# Cookbook Name:: elasticsearch-setup
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

data_bag = data_bag_item("app", node["data_bag_id"])
app_servers = data_bag["app_servers"]

service "elasticsearch" do
    service_name "elasticsearch"
    supports :restart => true, :status => true, :reload => true
    action [:enable, :start]
end

app_servers.each do |server|
    firewall_rule "elasticsearch" do
        port      9200
        source    "#{server}"
        command   :allow
    end
end
