#
# Cookbook Name:: build-tools
# Recipe:: ruby_ecosystem
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# ruby ecosystem setup
include_recipe "ruby_build"

# ruby_build dependencies
%w{ vim libssl-dev libreadline-dev zlib1g-dev }.each do |pkg_name|
  package pkg_name
end

ruby_build_ruby "2.1.4" do
    # due to failed issue when install RDoc
    environment({ "CONFIGURE_OPTS" => "--disable-install-doc --no-ri --no-rdoc" })
end

node["build-tools"]["gem_packages"].each do |pkg_name|
    gem_package pkg_name
end
