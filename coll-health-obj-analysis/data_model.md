## Data Model

### Create an Object using the Merritt inv_object_id as an identifier
```json
{
    "id": 3632877,
    "@timestamp": "2023-11-06T13:44:35-0800",
}
```

### Create a build Object to capture information known about the object the the Merritt Inventory Database
```json
{
    "id": 3632877,
    "@timestamp": "2023-11-06T13:44:35-0800",
    "build": {
      "id": 3632877
    },
    "@timestamp": "2023-11-06T13:44:35-0800",
}
```

### Add identfiers for the object.  These can be used to locate the object in Merritt or in OpenSearch.
```json
{
    "id": 3632877,
    "@timestamp": "2023-11-06T13:44:35-0800",
    "build": {
      "id": 3632877,
      "identifiers": {
        "ark": "ark:/99999/fk47708705",
        "localids": [
          "2023_10_30_1625_v1file"
        ]
      },
    },
    "@timestamp": "2023-11-06T13:44:35-0800",
}
```

### Add information about the containers for the object.  These allow for filtering for similar objects.
```json
{
    "id": 3632877,
    "@timestamp": "2023-11-06T13:44:35-0800",
    "build": {
      "id": 3632877,
      "identifiers": {},
      "containers": {
        "owner_ark": "ark:/13030/j2rn30xp",
        "owner_name": "UC3 Merritt administrator",
        "coll_ark": "ark:/13030/m5rn35s8",
        "coll_name": "Merritt demo",
        "mnemonic": "merritt_demo",
        "collection_tags": [
          "tag_test_set"
        ],
        "campus": "Other"
      },
    },
    "@timestamp": "2023-11-06T13:44:35-0800",
}
```

### Add metadata for the object.  The Merritt inventory database maintains minimal metadata for each object.
```json
{
    "id": 3632877,
    "@timestamp": "2023-11-06T13:44:35-0800",
    "build": {
      "id": 3632877,
      "identifiers": {},
      "containers": {},
      "metadata": {
        "erc_who": "(:unas)",
        "erc_what": "2023_10_30_1625_v1file v1_file.md.v2",
        "erc_when": "(:unas)",
        "erc_where": "ark:/99999/fk47708705 ; 2023_10_30_1625_v1file"
      },
    },
    "@timestamp": "2023-11-06T13:44:35-0800",
}
```

### Add detailed information about Merritt System Files for the object.
```json
{
    "id": 3632877,
    "@timestamp": "2023-11-06T13:44:35-0800",
    "build": {
      "id": 3632877,
      "identifiers": {},
      "containers": {},
      "metadata": {},
      "system": [
        {
          "version": 1,
          "last_version_present": 2,
          "source": "system",
          "pathname": "system/mrt-dc.xml",
          "billable_size": 149,
          "mime_type": "application/xml",
          "digest_type": "sha-256",
          "digest_value": "f40dd72e54b7e93c389895de1c13922fe5ac2ac226d7159a9704ae6f19a67929",
          "created": "2023-10-30 16:29:27 -0700",
          "pathtype": "file",
          "ext": "xml"
        },
        {
          "version": 2,
          "last_version_present": 2,
          "source": "system",
          "pathname": "system/mrt-erc.txt",
          "billable_size": 135,
          "mime_type": "text/plain",
          "digest_type": "sha-256",
          "digest_value": "2bedd9c897320081a275393d72fbabe1f777795e4a56773d9c48da7608ac2c32",
          "created": "2023-10-30 16:29:28 -0700",
          "pathtype": "file",
          "ext": "txt"
        }
      ],
    },
    "@timestamp": "2023-11-06T13:44:35-0800",
}
```

### Add detailed information about Merritt Producer Files for the object.
_Detailed information will be recorded for up to 1000 objects._
```json
{
    "id": 3632877,
    "@timestamp": "2023-11-06T13:44:35-0800",
    "build": {
      "id": 3632877,
      "identifiers": {},
      "containers": {},
      "metadata": {},
      "system": [],
      "producer": [
        {
          "version": 1,
          "last_version_present": 2,
          "source": "producer",
          "pathname": "producer/v1_file.md",
          "billable_size": 4,
          "mime_type": "text/x-web-markdown",
          "digest_type": "sha-256",
          "digest_value": "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08",
          "created": "2023-10-30 16:29:27 -0700",
          "pathtype": "file",
          "ext": "md"
        },
        {
          "version": 2,
          "last_version_present": 2,
          "source": "producer",
          "pathname": "producer/v1_file.md.v2",
          "billable_size": 4,
          "mime_type": "text/plain",
          "digest_type": "sha-256",
          "digest_value": "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08",
          "created": "2023-10-30 16:29:28 -0700",
          "pathtype": "file",
          "ext": "v2"
        }
      ],
    },
    "@timestamp": "2023-11-06T13:44:35-0800",
}
```

### Add summary information about the set of files found in the object
_includes ALL files, not just the first 1000 files_
```json
{
    "id": 3632877,
    "@timestamp": "2023-11-06T13:44:35-0800",
    "build": {
      "id": 3632877,
      "identifiers": {},
      "containers": {},
      "metadata": {},
      "system": [],
      "producer": [],
      "file_counts": {
        "deleted": 0,
        "empty": 0,
        "producer": 2,
        "system": 6
      },
      "mimes_for_object": [
        {
          "mime": "text/x-web-markdown",
          "count": 1
        },
        {
          "mime": "text/plain",
          "count": 1
        }
      ],
    },
    "@timestamp": "2023-11-06T13:44:35-0800",
}
```

### Capture version information about the object and the last modified date
```json
{
    "id": 3632877,
    "@timestamp": "2023-11-06T13:44:35-0800",
    "build": {
      "id": 3632877,
      "identifiers": {},
      "containers": {},
      "metadata": {},
      "system": [],
      "producer": [],
      "file_counts": {},
      "mimes_for_object": [],
      "version": 2,
      "modified": "2023-10-30T16:29:29-07:00",
    },
    "@timestamp": "2023-11-06T13:44:35-0800",
}
```

### Capture embargo information about the object (if present)
```json
{
    "id": 3632877,
    "@timestamp": "2023-11-06T13:44:35-0800",
    "build": {
      "id": 3632877,
      "identifiers": {},
      "containers": {},
      "metadata": {},
      "system": [],
      "producer": [],
      "file_counts": {},
      "mimes_for_object": [],
      "version": 2,
      "modified": "2023-10-30T16:29:29-07:00",
      "embargo_end_date": "",
    },
    "@timestamp": "2023-11-06T13:44:35-0800",
}
```

### Capture metadata sidecar information about the object
_If present in the inventory database **inv_metadatas** table_
```json
{
    "id": 3632877,
    "@timestamp": "2023-11-06T13:44:35-0800",
    "build": {
      "id": 3632877,
      "identifiers": {},
      "containers": {},
      "metadata": {},
      "system": [],
      "producer": [],
      "file_counts": {},
      "mimes_for_object": [],
      "version": 2,
      "modified": "2023-10-30T16:29:29-07:00",
      "embargo_end_date": "",
    },
    "@timestamp": "2023-11-06T13:44:35-0800",
}
```
