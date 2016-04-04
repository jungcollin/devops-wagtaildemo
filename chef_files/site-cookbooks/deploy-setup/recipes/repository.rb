#
# Cookbook Name:: deploy-setup
# Recipe:: repository
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# Repository's information
git_repo = node["deploy-setup"]["git_repo"]

# User's information
deploy_user = node["deploy-setup"]["user"]
home_path = deploy_user["home_path"]
deploy_key_path = "#{home_path}/.ssh/deploy_key.pem"
wrap_ssh_path = "#{home_path}/.ssh/wrap-ssh4git.sh"

# write deploy key content from secure data bag
file "#{deploy_key_path}" do
    content git_repo["deploy_key"]
    owner deploy_user["name"]
    mode "0600"
end

# @ref: https://docs.chef.io/resource_git.html
template wrap_ssh_path do
    source  "wrap-ssh4git.sh.erb"
    user    deploy_user["name"]
    group   deploy_user["group"]
    mode    "0755"
    variables(:deploy_key_path => deploy_key_path)
end

# fetch specfic revision of repository
git node["deploy-setup"]["deploy_path"] do
    repository  git_repo["repository"]
    revision    git_repo["revision"]
    depth       1
    user        deploy_user["name"]
    group       deploy_user["group"]
    action      "sync"
    ssh_wrapper wrap_ssh_path
end
