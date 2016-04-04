#
# Cookbook Name:: build-tools
# Recipe:: node_ecosystem
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

package "curl"

bash "install nodejs" do
    code <<-EOH
    curl -sL https://deb.nodesource.com/setup_0.12 | sudo bash -
    EOH
    only_if { which('node').nil? }
end

# nodejs ecosystem setup
# ref: https://github.com/nodesource/distributions
package "nodejs"

# set owner user for .npm directory
directory "#{node["deploy-setup"]["user"]["home_path"]}/.npm" do
    owner       node["deploy-setup"]["user"]["name"]
    recursive   true
    action      :create
end

bash "install npm global packages" do
    code <<-EOH
    npm install -g #{node["build-tools"]["npm_packages"].join(" ")}
    EOH
    only_if { node["build-tools"]["npm_packages"].any? { |pkg_name| which(pkg_name).nil? } }
end
