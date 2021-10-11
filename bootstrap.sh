#!/bin/bash
export HAB_LICENSE=accept
export CHEF_LICENSE=accept

useradd hab || echo 'hab user exists'

if chef --version 1> /dev/null 2>&1 ; then
  echo 'chef-workstation is already installed'
else
  if ls "/kitchen/.kitchen/chef-workstation"* 1> /dev/null 2>&1 ; then
    dnf -y install "/kitchen/.kitchen/chef-workstation"*
  else
    curl -L https://omnitruck.chef.io/install.sh | bash -s -- -P chef-workstation
  fi
fi

if hab svc status ; then
  echo "Habitat supervisor is running"
else
  echo "Starting Habitat supervisor"
  cd /tmp
  nohup hab sup run &
  i=0
  while [ $i -lt 10 ]
  do
    hab svc status 1> /dev/null 2>&1 || echo "Waiting for Habitat supervisor to start"
    sleep 5
    i=$((i+1))
  done
  hab svc status 1> /dev/null 2>&1 || ( echo "Habitat supervisor failed to start" && exit 1 )
fi

if [ -f /kitchen/results/last_build.env ]; then
  source /kitchen/results/last_build.env
  hab pkg install /kitchen/results/${pkg_artifact}
  hab svc load ${pkg_ident} --force
fi

