select
  distinct substr(f.pathname, 10) fname
from 
  inv_collections c
inner join inv_collections_inv_objects icio 
  on c.id = icio.inv_collection_id 
inner join inv_objects o 
  on o.id = icio.inv_object_id 
inner join inv_files f 
  on f.inv_object_id = o.id and source = 'producer'
where
  c.mnemonic = 'ucla_pal_museum'
order by fname;