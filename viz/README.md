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

## Logstash Filters
```
filter {
  json {
    skip_on_invalid_json => true
    source => "message"
    target => "json_data"
    add_tag => [ "_message_json_parsed" ]
  }
}

filter {
  date {
    locale => en
    match => [ "[json_data][date_added]", "yyyy-MM-dd HH:mm:ss Z" ]
    target => "@timestamp"
  }
}
```

## Send to OpenSearch - All 10 years in a single file
_See https://github.com/CDLUC3/opensearch-tutorial/blob/main/README.md to launch tutorial in docker_

```
output {
  opensearch {
    hosts => ["https://opensearch:9200"]
    user => "admin"
    password => "admin"
    ssl_certificate_verification => false
    index => "data-billing"
  }
}
```
