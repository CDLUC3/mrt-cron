#!/bin/bash
cd coll-health
echo
pwd
echo '==========='
bundle install
bundle update
bundle exec rubocop || exit
cd ../coll-health-obj-analysis
echo
pwd
echo '==========='
bundle install
bundle update
bundle exec rubocop || exit
cd ../consistency-driver
echo
pwd
echo '==========='
bundle install
bundle update
bundle exec rubocop || exit
