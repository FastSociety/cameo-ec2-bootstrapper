#!/bin/bash -ex

## Generic bootrap script for Ubuntu-11.10-based EC2 instances
## This script should be run via EC2 UserData, but works just as well in a VM.
## It will install the Puppetlabs APT sourcelist, then install and configure a
## basic Puppet Agent.
##
## Usage: ec2-bootrap.sh foo_node production puppetmaster.puppetlabs.com

NODE_NAME=$1
ENVIRONMENT=$2
PUPPETMASTER=$3

# Prepare APT
export DEBIAN_FRONTEND=noninteractive

# Install Puppetlabs APT sourcelist package
wget http://apt.puppetlabs.com/puppetlabs-release-oneiric.deb
dpkg -i puppetlabs-release-oneiric.deb

# Update APT
apt-get update

apt-get install -y python-setuptools
easy_install pip

# Install Puppet
apt-get install -y puppet

# Install basic Puppet Agent puppet.conf
cat <<EOF > /etc/puppet/puppet.conf
[main]
ssldir=\$vardir/ssl
report=true
environment=${ENVIRONMENT}
certname=${NODE_NAME}.${ENVIRONMENT}.$(facter ec2_instance_id).$(facter ec2_public_hostname)
server=${PUPPETMASTER}
EOF

# Enable and start Puppet
sed -i 's/START=no/START=yes/' /etc/default/puppet
service puppet start