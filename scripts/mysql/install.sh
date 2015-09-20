#!/bin/bash

echo 'mysql-server mysql-server/root_password password root' | debconf-set-selections
echo 'mysql-server mysql-server/root_password_again password root' | debconf-set-selections

apt-get update
apt-get install -y libmysqlclient-dev mysql-server
