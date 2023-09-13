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

if [ "$2" == "placeholder" ]
then
  ${HOME}/bin/uc3-mysql.sh billing -- -e "select distinct ogroup, own_name, collection_name, mnemonic, date(now()) as date_added, mime_type, mime_group, inv_owner_id, inv_collection_id, 'producer' as source, 0 as count_files, 0 as full_size, 0 as billable_size from owner_coll_mime_use_details;" >> ${COLLHDATA}/billing.tsv
else
  ${HOME}/bin/uc3-mysql.sh billing -- -e "select * from owner_coll_mime_use_details where date_added > '${start}' order by date_added;" >> ${COLLHDATA}/billing.tsv
fi

ruby make_json.rb "$start" ${COLLHDATA}/billing.tsv >> ${COLLHDATA}/billing.ndjson
# ruby placeholder_json.rb ${COLLHDATA}/billing.tsv >> ${COLLHDATA}/billing.ndjson