#
# Cookbook Name:: app-setup
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

deploy_user = node["deploy-setup"]["user"]
venv_path = node["django-setup"]["venv_path"]

data_bag = data_bag_item("app", node["data_bag_id"])
data_bag_postgresql = data_bag["postgresql"]
data_bag_redis = data_bag["redis"]

# Load s3 configuration from data bag file
# To write it into environment variables
data_bag_s3 = data_bag["s3"]

template "#{deploy_user["home_path"]}/.bash_profile" do
    source  "bash_profile.erb"
    owner   deploy_user["name"]
    user    deploy_user["name"]
    group   deploy_user["group"]
    mode    "0755"
    variables(
        :postgresql => data_bag_postgresql,
        :redis      => data_bag_redis,
        :s3         => data_bag_s3,
    )
end

# migration step
script_path = "#{node["deploy-setup"]["app_path"]}/bin"

# grant execute persmision before running the script
bash "add execute permission for all scripts in bin folder #{script_path}" do
    code "chmod u+x #{script_path}/*.sh"
end

# for running script after deploying
bash "post deploy" do
    code <<-EOH
/bin/su - #{deploy_user["name"]} -c "./bin/post_deploy.sh"
EOH
    creates "/var/run/postsetupuid.bdb"
    action :run
end

# Don't install `uWSGI` recipe for development environment
unless node.chef_environment == "development"
    include_recipe "app-setup::uwsgi"
    include_recipe "app-setup::uwsgi_socket"
end
