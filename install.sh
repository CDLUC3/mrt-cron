#!/bin/bash
cd /dpr2/installs/mrt-cron
git pull
cd coll-health
echo
pwd
echo '==========='
bundle install
cd ../coll-health-obj-analysis
echo
pwd
echo '==========='
bundle install
cd ../consistency-driver
echo
pwd
echo '==========='
bundle install
