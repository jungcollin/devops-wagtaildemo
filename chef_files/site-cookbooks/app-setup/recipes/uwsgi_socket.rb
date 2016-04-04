#
# Cookbook Name:: app-setup
# Recipe:: uwsgi_socket
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

data_bag = data_bag_item("app", node["data_bag_id"])
data_bag_postgresql = data_bag["postgresql"]
data_bag_redis = data_bag["redis"]
data_bag_load_balancer = data_bag["load-balancer-setup"]

# Load s3 configuration from data bag file
# To write it into environment variables
data_bag_s3 = data_bag["s3"]

project_name = data_bag["project_name"]

template "/etc/uwsgi/vassals/django-socket.ini" do
    user        node["deploy-setup"]["user"]["name"]
    group       node["deploy-setup"]["user"]["group"]
    source      "django-socket.ini.erb"
    notifies    :restart, "service[uwsgi]", :delayed
    variables(
        :environment    => node.chef_environment,
        :project_name   => project_name,
        :postgresql     => data_bag_postgresql,
        :redis          => data_bag_redis,
        :s3             => data_bag_s3,
    )
end

file "/var/run/uwsgi-socket.pid" do
    user        node["deploy-setup"]["user"]["name"]
    group       node["deploy-setup"]["user"]["group"]
end

service "uwsgi" do action :restart end

# set up firewall rule for the output socket
firewall_rule "uwsgi-socket" do
    port        node["app-setup"]["uwsgi_socket"]
    source      data_bag_load_balancer["host"]
    command     :allow
end
