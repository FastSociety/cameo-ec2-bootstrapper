#!/bin/bash -ex

## Generic bootrap script for Ubuntu-based EC2 instances
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
#PUPPETLABS_RELEASE_DEB=puppetlabs-release-$(lsb_release -sc).deb
#wget http://apt.puppetlabs.com/${PUPPETLABS_RELEASE_DEB}
#dpkg -i ${PUPPETLABS_RELEASE_DEB}

# Update APT
apt-get update

apt-get install -y python-setuptools python-pip

# Install Puppet
apt-get install -y puppet

#Ensure vital SG Groups are set
FACTER_EC2_SGS=$(facter ec2_security_groups)
echo ${FACTER_EC2_SGS} | grep sg_${ENVIRONMENT}_puppet || nc -w0 -u syslog.logs.inet.cameo.tv 514 <<< "<131>`date --rfc-3339=ns` `hostname` Ec2_Bootstrap: Failed to detect SG for Puppetmaster!"
echo ${FACTER_EC2_SGS} | grep sg_${ENVIRONMENT}_logs || nc -w0 -u syslog.logs.inet.cameo.tv 514 <<< "<131>`date --rfc-3339=ns` `hostname` Ec2_Bootstrap: Failed to detect SG for Logserver!"

# Install basic Puppet Agent puppet.conf
cat <<EOF > /etc/puppet/puppet.conf
[main]
ssldir=\$vardir/ssl
rundir=/var/run/puppet
report=true
#runinterval=300
environment=${ENVIRONMENT}
certname=${NODE_NAME}.${ENVIRONMENT}.$(facter ec2_instance_id).$(facter ec2_public_hostname)
server=${PUPPETMASTER}
EOF

# Enable and start Puppet
sed -i 's/START=no/START=yes/' /etc/default/puppet
service puppet start