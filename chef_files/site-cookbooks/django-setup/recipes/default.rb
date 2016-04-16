#
# Cookbook Name:: django-setup
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

data_bag = data_bag_item("app", node["data_bag_id"])
data_bag_django_setup = data_bag["django-setup"]

node.set["django-setup"] = Chef::Mixin::DeepMerge.merge(node.default["django-setup"], data_bag_django_setup)

home_path = node["deploy-setup"]["user"]["home_path"]
node.set["django-setup"]["venv_path"] = venv_path = "#{home_path}/#{node["django-setup"]["venv_dir"]}"

# 1. Fix issue: `Error: pg_config executable not found.`
# when install psycopg2 from `pip install psycopg2`
#
# install: libpq-dev python-dev
#
# @ref: https://web.archive.org/web/20110305033324/http://goshawknest.wordpress.com/2011/02/16/how-to-install-psycopg2-under-virtualenv/
#
#
# 2. Fix issue: `decoder jpeg not available pillow`
#
# insall: libjpeg-dev
#
# @ref: http://stackoverflow.com/questions/12555831/decoder-jpeg-not-available-error-when-following-django-photo-app-tutorial
#
# 3. Fix issue: `!!! no internal routing support, rebuild with pcre support !!!`
# when run uwsgi emperor
#
# install: libpcre3 libpcre3-dev
#
# @ref: http://stackoverflow.com/questions/21669354/rebuild-uwsgi-with-pcre-support
#
# 4. Fix issue: `Could not find function xmlCheckVersion in library libxml2. Is libxml2 installed?`
#
# install: libxml2-dev libxslt1-dev
#
# @ref: http://stackoverflow.com/questions/5178416/pip-install-lxml-error
#
%w{ libpq-dev python-dev python3-dev libjpeg-dev libpcre3 libpcre3-dev libxml2-dev libxslt1-dev }.each do |pkg_name|
    package pkg_name
end

# prepare the cache folder for pip to prevent permission issue
# because ~/.cache/pip mode is 0700 by default
# need to grant the permission so that root user can access it
directory "#{home_path}/.cache" do
    user        node["deploy-setup"]["user"]["name"]
    group       node["deploy-setup"]["user"]["group"]
    owner       node["deploy-setup"]["user"]["name"]
    recursive   true
    mode        "0755"
    action      :create
end

# specify python interpreter
python_runtime "3"

# install new virtualenv
python_virtualenv venv_path do
    user    node["deploy-setup"]["user"]["name"]
    group   node["deploy-setup"]["user"]["group"]
end

# set owner user for virtualenv directory
directory venv_path do
    owner       node["deploy-setup"]["user"]["name"]
    recursive   true
    action      :create
end

requirement_file_path = "#{node["deploy-setup"]["app_path"]}/requirements.txt"

# the requirement file will be found via chef_environment
pip_requirements requirement_file_path do
    virtualenv  venv_path
    action      :install
    only_if     { File.exists?(requirement_file_path) }
end
