time uc3-mysql.sh > mimefiles.tsv << HERE
select
  c.mnemonic,
  f.mime_type,
  o.ark,
  f.pathname
from 
  inv.inv_collections c
inner join inv.inv_collections_inv_objects icio 
  on c.id = icio.inv_collection_id 
inner join inv.inv_objects o 
  on o.id = icio.inv_object_id
inner join inv.inv_files f 
  on f.inv_object_id = icio.inv_object_id and source = 'producer' and f.billable_size = f.full_size
/*where mnemonic='ucb_lib_prechmat'*/
order by 
  c.mnemonic,
  f.mime_type,
  o.ark,
  f.pathname
;
HERE

ruby mimefilelist.rb mimefiles.tsv