#! /bin/sh

# export COLLHDATA=/dpr2/apps/mrt-cron/coll_health/data; ./billing_viz.sh
#
# In dev...
# export COLLHDATA=$PWD; ./billing_viz.sh

# uc3-mysql.sh billing -- -e "select * from owner_coll_mime_use_details;" | ruby make_json.rb > ${COLLHDATA}/billing.ndjson
if [ "$1" == "all" ]
then
  cat /dev/null > ${COLLHDATA}/billing.tsv
  cat /dev/null > ${COLLHDATA}/billing.ndjson
  start='2013-05-22 00:00:00'
elif [ "$1" == "" ]
then
  start="$(tail -1 ${COLLHDATA}/billing.tsv | cut -f5)"
else 
  start=$1
fi
echo ${start}
uc3-mysql.sh billing -- -e "select * from owner_coll_mime_use_details where date_added > '${start}' order by date_added;" >> ${COLLHDATA}/billing.tsv

ruby make_json.rb "$start" ${COLLHDATA}/billing.tsv >> ${COLLHDATA}/billing.ndjson