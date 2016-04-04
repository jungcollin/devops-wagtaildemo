#!/bin/bash

PROJECT_NAME="sdvdev@asoft"

# Gitlab CI server
CI_SERVER_URL="https://gitlab.asoft-python.com/ci"
REGISTRATION_TOKEN="dab81f449ab47776e9c2c3d7e2e2e2"
TAG_LIST="ubuntu/trusty64,virtualenv,libpq-dev,python3-dev,chefdk,knife-solo"
EXECUTOR="shell"

# backup CA system file
sudo cp /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt.bak

# add server key into CA file for authorization with GitLab server
sudo chmod 777 /etc/ssl/certs/ca-certificates.crt
sudo cat /vagrant/gitlab-https-ca.crt >> /etc/ssl/certs/ca-certificates.crt
sudo chmod 644 /etc/ssl/certs/ca-certificates.crt

# Add GitLab's official repository via apt-get for Debian/Ubuntu
wget https://packages.gitlab.com/install/repositories/runner/gitlab-ci-multi-runner/script.deb.sh -O - | sudo bash

# Install pip into local user
wget https://bootstrap.pypa.io/ez_setup.py -O - | sudo python3
wget https://bootstrap.pypa.io/get-pip.py -O - | sudo python3

# Install virtualenv
sudo pip install virtualenv

# Install gitlab-ci-multi-runner package
sudo apt-get -y install gitlab-ci-multi-runner

# Install dependencies for psycopg2 (Psycopg: PostgreSQL + Python)
sudo apt-get -y install libpq-dev python-dev python3-dev

# Install chef-dk for deploy stage
curl -LO https://www.chef.io/chef/install.sh && sudo bash ./install.sh -P chefdk -v 0.7.0 && rm install.sh

# Install knife-solo to importing knife solo command
# IMPORTANT: this will install to global gems, so gitlab-runner user can access it
sudo chef gem install knife-solo --no-user-install

# Register the runner
sudo gitlab-ci-multi-runner register \
    --non-interactive \
    --url "$CI_SERVER_URL" \
    --registration-token "$REGISTRATION_TOKEN" \
    --name "$PROJECT_NAME" \
    --tag-list "$TAG_LIST" \
    --executor "$EXECUTOR"

# Reload the runner
sudo gitlab-ci-multi-runner restart
