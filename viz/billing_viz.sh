#! /bin/sh

# COLLHDATA=/dpr2/apps/mrt-cron/coll_health/data ./billing_viz.sh
#
# In dev...
# COLLHDATA=$PWD ./billing_viz.sh
uc3-mysql.sh billing -- -e "select * from owner_coll_mime_use_details;" | ruby make_json.rb > ${COLLHDATA}/billing.ndjson