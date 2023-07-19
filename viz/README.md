## Create Json Files from Merritt Billing Database
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
- [SQL script](billing_viz.sh)
- [Convert to Json](make_json.rb)
