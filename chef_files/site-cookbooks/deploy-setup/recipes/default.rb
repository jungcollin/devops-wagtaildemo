#
# Cookbook Name:: deploy-setup
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

data_bag = data_bag_item("app", node["data_bag_id"])
data_bag_deploy_setup = data_bag["deploy-setup"]

node.set["deploy-setup"] = Chef::Mixin::DeepMerge.merge(node.default["deploy-setup"], data_bag_deploy_setup)

project_name = data_bag["project_name"]
deploy_user  = node["deploy-setup"]["user"]

node.set["deploy-setup"]["user"]["home_path"] = home_path = "/home/#{deploy_user["name"]}"
node.set["deploy-setup"]["deploy_path"] = deploy_path = "#{home_path}/#{node["deploy-setup"]["deploy_dir"]}"
node.set["deploy-setup"]["app_path"] = deploy_path

#####################################################
# Enable firewall
#####################################################
firewall "default"

user deploy_user["name"] do
    if deploy_user["password"]
        password deploy_user["password"]
    end
    home "#{home_path}"
    supports manage_home: true
    shell "/bin/bash"
end

group deploy_user["group"] do
    action  :create
    members deploy_user["name"]
    append  true
end

# grant permission for user within its own home
# the mode "0755" is important
# that allow another user like www-data can read the file in which deploy_user["name"]
directory home_path do
    user        deploy_user["name"]
    group       deploy_user["group"]
    mode        "0755"
end

# become sudoers
bash "Add user to sudoers" do
  user "root"
  code <<-EOH
  usermod -a -G sudo "#{deploy_user["name"]}"
  EOH
end

directory "#{home_path}/.ssh" do
    action :create
    owner deploy_user["name"]
    mode "0744"
    not_if { ::File.exists?("#{home_path}/.ssh") }
end

file "#{home_path}/.ssh/authorized_keys" do
    action :create
    owner deploy_user["name"]
    mode "0744"
    not_if { ::File.exists?("#{home_path}/.ssh/authorized_keys") }
end

if deploy_user["allowed_ssh_keys"] && deploy_user["allowed_ssh_keys"].is_a?(Array)
    ruby_block "authorize keys" do
        block do
            "rails c"

            new_text = <<-EOS
#{deploy_user["allowed_ssh_keys"].join("\n")}
            EOS

            authorized_keys_path = "#{home_path}/.ssh/authorized_keys"

            f = File.open(authorized_keys_path)
            file = f.read
            f.close

            unless file.include?(new_text)
                new_file = File.new("#{authorized_keys_path}.new", "w")
                new_file.write file
                new_file.write new_text
                new_file.close

                File.rename("#{authorized_keys_path}", "#{authorized_keys_path}.old")
                File.rename("#{authorized_keys_path}.new", "#{authorized_keys_path}")
                File.delete("#{authorized_keys_path}.old")
            end
        end
    end
end

# Clone the git repository once providing the git repository information
# and not is development environment
if node["deploy-setup"]["git_repo"] and node.chef_environment != "development"
    include_recipe "deploy-setup::repository"
end
