#! /bin/sh

mkdir -p /tmp/viz
uc3-mysql.sh billing -- -e "select * from owner_coll_mime_use_details;" | ruby make_json.rb > billing.ndjson