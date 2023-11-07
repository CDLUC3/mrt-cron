# Merritt Object Health Data Model

The Merritt Object Health process will build a highly structured JSON document for each of the 4 million+ objects stored in the Merritt preservation system.

The JSON documents will be designed to support searching, filtering and faceting using OpenSearch for analysis.

The process consists of 3 phases which will be captured within the object JSON.

- **Build**: Extract known information about an object from the inventory database
- **Analysis**: Apply a set of **Analysis Tasks** to the build structure to classify and categorize the objects
- **Tests**: Apply a set of **Object Tests** against the build and analysis structures each of which will result in one of the following status values
  - SKIP: A test is skipped if it is not applicable to a specific object or to its containing collection
  - PASS: The object meets the optimal criteria for a Merritt object
  - INFO: The object does not meet the optimal criteria for a Merritt object but no action is expected
  - WARN: The object does not meet the optimal criteria for a Merritt object and some investigation is recommended 
  - FAIL: The object does not meet the criteria for a Merritt object and remediation is recommended 

## Object Build Process
The **Build** process is intended to extract and assemble known information about an object.

Because some Merritt objects contain tens of thousands of objects, this phase of processing does perform minimal analysis of each file within an object.  

Only the first 1000 files within an object will be detailed in the build structure.

### Create an object using the Merritt _inv_object_id_ as an identifier

<details>
<summary>Sample Json</summary>
    
```json
{
    "id": 3632877,
    "@timestamp": "2023-11-06T13:44:35-0800",
}
```

</details>

### Create the _build_ property to capture information known about the object the the Merritt Inventory Database
<details>
<summary>Sample Json</summary>
    
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

</details>

### Add identfiers for the object.  

These can be used to locate the object in Merritt or in OpenSearch.

<details>
<summary>Sample Json</summary>
    
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

</details>

### Add information about the containers for the object.  

These allow for filtering for similar objects.

<details>
<summary>Sample Json</summary>
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

</details>

### Add metadata for the object.  

The Merritt inventory database maintains minimal metadata (what, who, when, where) for each object.

<details>
<summary>Sample Json</summary>

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

</details>

### Add detailed information about Merritt System Files for the object.


<details>
<summary>Sample Json</summary>

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
</details>

### Add detailed information about Merritt Producer Files for the object.
_Detailed information will be recorded for up to 1000 objects._


<details>
<summary>Sample Json</summary>

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
</details>

### Add summary information about the set of files found in the object
_includes ALL files, not just the first 1000 files_


<details>
<summary>Sample Json</summary>

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
</details>

### Capture version information about the object and the last modified date

<details>
<summary>Sample Json</summary>

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
</details>

### Capture embargo information about the object (if present)

<details>
<summary>Sample Json</summary>

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
</details>

### Capture metadata sidecar information about the object
_If present in the inventory database **inv_metadatas** table. Data contains a dump of dublin core type metadata._


<details>
<summary>Sample Json</summary>
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
      "sidecar": [
        {
          "identifier": [],
          "creatorName": [],
          "nameIdentifier": [],
          "affiliation": [],
          "title": [],
          "publisher": [],
          "resourceType": [],
          "publicationYear": [],
          "subject": [],
          "description": []
        },
        {}
      ]
    },
    "@timestamp": "2023-11-06T13:44:35-0800",
}
```
</details>

## Object Analysis Process

## Object Health Tests Process
