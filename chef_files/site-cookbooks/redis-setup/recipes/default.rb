#
# Cookbook Name:: redis-setup
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

data_bag = data_bag_item("app", node["data_bag_id"])
app_servers = data_bag["app_servers"]

include_recipe "redisio"
include_recipe "redisio::enable"

app_servers.each do |server|
    firewall_rule "redis" do
        port      6379
        source    "#{server}"
        command   :allow
    end
end
