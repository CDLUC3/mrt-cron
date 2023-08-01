getmimes() {
uc3-mysql.sh >> out/mimefiles.tsv << HERE
select
  f.id,
  c.mnemonic,
  f.mime_type,
  o.ark,
  f.pathname,
  f.created, 
  f.billable_size,
  ol.ogroup,
  ol.own_name,
  CASE
      WHEN mime_type = 'text/csv' THEN 'data'
      WHEN mime_type = 'plain/turtle' THEN 'data'
      WHEN mime_type REGEXP '^application/(json|atom\.xml|marc|mathematica|x-hdf|x-matlab-data|x-sas|x-sh$|x-sqlite|x-stata)' THEN 'data'
      WHEN mime_type REGEXP '^application/.*(zip|gzip|tar|compress|zlib)' THEN 'container'
      WHEN mime_type REGEXP '^application/(x-font|x-web)' THEN 'web'
      WHEN mime_type REGEXP '^application/(x-dbf|vnd\.google-earth)' THEN 'geo'
      WHEN mime_type REGEXP '^application/vnd\.(rn-real|chipnuts)' THEN 'audio'
      WHEN mime_type REGEXP '^application/mxf' THEN 'video'
      WHEN mime_type REGEXP '^(message|model)/' THEN 'text'
      WHEN mime_type REGEXP '^(multipart|text/x-|application/java|application/x-executable|application/x-shockwave-flash)' THEN 'software'
      WHEN mime_type REGEXP '^application/' THEN 'text'
      ELSE substring_index(mime_type, '/', 1)
    END as mime_group
from 
  inv.inv_collections c
inner join inv.inv_collections_inv_objects icio 
  on c.id = icio.inv_collection_id 
inner join inv.inv_objects o 
  on o.id = icio.inv_object_id
inner join billing.owner_list ol
  on o.inv_owner_id = ol.inv_owner_id
inner join inv.inv_files f 
  on f.inv_object_id = icio.inv_object_id 
where 
  f.created >= '$1' and f.created < '$2' 
and source = 'producer' and f.billable_size = f.full_size
;
HERE
cnt=`wc -l out/mimefiles.tsv`
echo "$1 $cnt $(date)"
}

getallmimes() {
  d='2013-05-22'
  dd=`date -d "+1 day" "+%Y-%m-%d"`
  while [[ $d < $dd ]]
  do 
    nd=`date -d "$d +1 day" "+%Y-%m-%d"`
    getmimes $d $nd 
    d=$nd
  done
}

mkdir -p out
cat /dev/null > out/mimefiles.tsv
getallmimes

#ruby mimefilelist.rb out/mimefiles.tsv