# Merritt Collection Health Report

## System Design

```
INV DB --> Bulk Extract  --> TSV Files* --> Analysis Prog --> JSON Files* --> OpenSearch 
INV DB --> Daily Extract --> TSV Files* --> Analysis Prog --> JSON Files* --> OpenSearch 

*Question: store locally or on ZFS?  With the bulk extract process, the files could be re-created if needed.

Extractions to perform (https://github.com/CDLUC3/mrt-doc/issues/1544)
- Daily Billing Summary (if needed)
  - unique id (for replacement) - does not currently exist; replace the entire index instead
  - time: data_added
- Producer Files Extract
  - unique id (for replacement) - inv_file_id
  - time: created
- Objects Extract
  - unique id (for replacement) - inv_object_id
  - time: created or modified?
```

## Bulk Extract Process
- Recreate data for all TSV files since Merritt beginnings (2013)
- Extract records by date (Year or Quarter or Month) depending on efficiency
- Create/replace TSV files
- The need to re-run should be infrequent -- only if queries need to change

## Daily Extract Process
- Query for new records since last run
- Append TSV files

## Analysis Program
- Can be run only on the newest records OR it can be run to re-process everything
- Unlike the extract process, a full rerun may occur with regularity esp if "Rule Files (yaml)" change
- Yaml files guide the analysis program
  - Registry of at-risk mime types
  - Registry of Merritt "standard" mime types
  - Registry of expected mime types based on collection intake form
  - Filename regex patterns to identify standard metadata files
- Analysis of files within an object is more complicated

## Daily Billing Extract
```
select * from owner_coll_mime_use_details;
```

## Producer File Extract
```
select
  f.id,
  c.mnemonic,
  f.mime_type,
  o.ark,
  f.pathname,
  f.created
from 
  inv.inv_collections c
inner join inv.inv_collections_inv_objects icio 
  on c.id = icio.inv_collection_id 
inner join inv.inv_objects o 
  on o.id = icio.inv_object_id
inner join inv.inv_files f 
  on f.inv_object_id = icio.inv_object_id and source = 'producer' and f.billable_size = f.full_size
order by 
  f.id
limit 1000000
;
```