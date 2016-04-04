#
# Cookbook Name:: app-setup
# Recipe:: uwsgi
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# Configure uWSGI emperor deamon
#
# @usage: $ uwsgi --emperor /etc/uwsgi/vassals
# @ref: https://uwsgi-docs.readthedocs.org/en/latest/ImperialMonitors.html
directory "/etc/uwsgi" do
    user        node["deploy-setup"]["user"]["name"]
    group       node["deploy-setup"]["user"]["group"]
    mode        "0755"
    action      :create
end

# configure for emperor mode of uwsgi
directory "/etc/uwsgi/vassals"

# create uwsgi deamon
# @ref: http://uwsgi-docs.readthedocs.org/en/latest/Upstart.html
template "/etc/init/uwsgi.conf" do
    user        node["deploy-setup"]["user"]["name"]
    group       node["deploy-setup"]["user"]["group"]
    source      "uwsgi.conf.erb"
    mode        "0755"
end

# create log dir for uwsgi deamon
directory "/var/log/uwsgi" do
    user        node["deploy-setup"]["user"]["name"]
    group       node["deploy-setup"]["user"]["group"]
    mode        "0755"
    action      :create
end

# register the uwsgi deamon to run at startup
service "uwsgi" do action [:enable] end
