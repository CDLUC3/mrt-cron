#!/bin/bash
cd /dpr2/install/mrt-cron
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

# Stage
# set SSM_ROOT
# cd /dpr2/install/mrt-cron/consistency-driver && bundle exec ruby driver.rb
# cd /dpr2/install/mrt-cron/coll-health-obj-analysis && bundle exec ruby object_health.rb -h

# Prod
# set SSM_ROOT
# cd /dpr2/install/mrt-cron/consistency-driver && bundle exec ruby driver.rb
# cd /dpr2/install/mrt-cron/viz && export COLLHDATA=/dpr2/apps/mrt-cron/coll_health/data && ./billing_viz.sh
# cd /dpr2/install/mrt-cron/coll-health && export COLLHDATA=/dpr2/apps/mrt-cron/coll_health/data && ./mimefilelist.sh
# cd /dpr2/install/mrt-cron/coll-health-obj-analysis && bundle exec ruby object_health.rb -h
# cd /dpr2/install/mrt-cron/coll-health-obj-analysis && bundle exec ruby object_health.rb

