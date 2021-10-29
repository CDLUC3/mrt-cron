#!/bin/sh

${HOME}/bin/uc3-mysql.sh billing -- -e 'call update_billing_range();'
${HOME}/bin/uc3-mysql.sh billing -- -e 'call update_object_size();'
${HOME}/bin/uc3-mysql.sh billing -- -e 'call update_audits_processed();'
${HOME}/bin/uc3-mysql.sh billing -- -e 'call update_ingests_processed();'

${HOME}/bin/uc3-mysql.sh billing readwrite << EOF

delete from 
  daily_node_counts 
where 
  as_of_date = date(now());

insert into daily_node_counts (
  as_of_date,
  inv_node_id,
  number,
  object_count,
  object_count_primary,
  object_count_secondary,
  file_count,
  billable_size
)
select
  date(now()),
  n.id,
  n.number,
  count(inio.inv_object_id),
  sum(case when role ='primary' then 1 else 0 end),
  sum(case when role ='secondary' then 1 else 0 end),
  sum(os.file_count),
  sum(os.billable_size)
from
  inv.inv_nodes n
inner join inv.inv_nodes_inv_objects inio 
  on n.id = inio.inv_node_id
inner join object_size os
  on inio.inv_object_id = os.inv_object_id
group by 
  n.id,
  n.number;

start transaction;

delete from node_counts;

insert into node_counts(
  inv_node_id,
  number,
  object_count,
  object_count_primary,
  object_count_secondary,
  file_count,
  billable_size
) 
select
  inv_node_id,
  number,
  object_count,
  object_count_primary,
  object_count_secondary,
  file_count,
  billable_size
from 
  daily_node_counts
where
  as_of_date = date(now());

commit;

EOF