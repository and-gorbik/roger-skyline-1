#!/bin/bash

apt-get update >> /var/log/update_script.log
apt-get upgrade -y >> /var/log/update_script.log
