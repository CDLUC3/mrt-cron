#!/bin/sh

for i in 1 2 3 4 5; do ${HOME}/bin/uc3-mysql.sh billing -- -e 'call update_billing_range();' && break || echo "Retry Q1-${i}" && sleep 15; done
for i in 1 2 3 4 5; do ${HOME}/bin/uc3-mysql.sh billing -- -e 'call update_object_size();' && break || echo "Retry Q2-${i}" && sleep 15; done
for i in 1 2 3 4 5; do ${HOME}/bin/uc3-mysql.sh billing -- -e 'call update_audits_processed();' && break || echo "Retry Q3-${i}" && sleep 15; done
for i in 1 2 3 4 5; do ${HOME}/bin/uc3-mysql.sh billing -- -e 'call update_ingests_processed();' && break || echo "Retry Q4-${i}" && sleep 15; done

for i in 1 2 3 4 5; do ${HOME}/bin/uc3-mysql.sh billing readwrite << EOF && break || echo "Retry Q5-${i}" && sleep 15; done
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

EOF