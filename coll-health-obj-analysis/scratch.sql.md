Duplicate checksum

```sql
select source, digest_value, full_size, count(*) 
from inv_files 
where source='producer' and full_size=billable_size 
group by source, digest_value, full_size 
having count(*) > 1 
order by count(*)
```

File size dist in Merritt

```sql
select 
  a.fcount,
  count(*) as cn 
from (
  select inv_object_id, count(*) as fcount 
  from inv_files 
  where source='producer' and full_size=billable_size 
  group by inv_object_id
) as a
group by
  a.fcount 
order by
  a.fcount 
;
```
