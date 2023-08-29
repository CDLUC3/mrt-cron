# Create Json Files from Merritt Billing Database

This process will create one JSON record for every Merritt billing record.  

A billing record is a combination of date + collection + mimetype.  Aggregate totals are computed on a daily basis.

This dataset will allow the user to construct cumulative counts for the whole Merritt system.

TODO: if files have been deleted from Merritt, negative totals should be added into the billing dataset on the date of removal.

Inidividual filenames cannot be discovered in this dataset.

## Table Schema
```
MySQL [billing]> describe owner_coll_mime_use_details;
+-------------------+--------------------------------------+------+-----+---------+-------+
| Field             | Type                                 | Null | Key | Default | Extra |
+-------------------+--------------------------------------+------+-----+---------+-------+
| ogroup            | varchar(5)                           | NO   |     |         |       |
| own_name          | varchar(255)                         | YES  |     | NULL    |       |
| collection_name   | varchar(255)                         | YES  |     | NULL    |       |
| mnemonic          | varchar(255)                         | YES  |     | NULL    |       |
| date_added        | date                                 | YES  |     | NULL    |       |
| mime_type         | varchar(255)                         | YES  |     | NULL    |       |
| mime_group        | varchar(255)                         | YES  |     | NULL    |       |
| inv_owner_id      | int                                  | YES  |     | NULL    |       |
| inv_collection_id | int                                  | YES  |     | NULL    |       |
| source            | enum('consumer','producer','system') | YES  |     | NULL    |       |
| count_files       | bigint                               | YES  |     | NULL    |       |
| full_size         | bigint                               | YES  |     | NULL    |       |
| billable_size     | bigint                               | YES  |     | NULL    |       |
+-------------------+--------------------------------------+------+-----+---------+-------+
13 rows in set (0.02 sec)
```

## Code
- [Extract Script with SQL](billing_viz.sh)
- [Ruby Code to Convert TSV to Json](make_json.rb)

## Invocation

Set environment
```
export COLLHDATA=/dpr2/apps/mrt-cron/coll_health/data
cd {merrit-cron-install}/viz
```

Recreate file using data since 2013
```
./billing_viz.sh all
```

Append to file since last execution

_This process looks at the date of the last extracted record._
```
./billing_viz.sh
```

## Internal Documentation

- [Logstash and Cron Config](https://github.com/CDLUC3/uc3-ops-puppet-hiera/blob/main/fqsn/uc3-mrt-batch-prd.yaml)
- [Recreate OpenSearch Data Stream](https://github.com/CDLUC3/mrt-doc-private/blob/main/docs/system-recovery/open-search-dataset-management.md)
