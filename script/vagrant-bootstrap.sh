#!/bin/sh
set -e -x

# general maint
apt-get update
apt-get upgrade --yes

# rvm
apt-get install --yes curl build-essential
apt-get install --yes libreadline-gplv2-dev
apt-get build-dep --yes ruby1.8 ruby1.9.3
if [ ! -d .rvm ] ; then
    curl -L https://get.rvm.io | bash -s stable --ruby
fi

# other tools
apt-get install --yes git vim-nox

# req for the graphite-debs script
apt-get install --yes python-setuptools

# req for the Rakefile setup
apt-get install --yes python2.7 python2.7-dev libcairo-dev
