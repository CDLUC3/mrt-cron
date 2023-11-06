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

### Add identfiers
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



```mermaid
  graph TD;
      subgraph Object Health Publishing Process
        GATHER(Gather Objects)
        BUILD(Build Objects)
        ANALYZE(Analyze Objects)
        TEST(Test Objects)
        Publish(Publish Changes)
        CODE["Analysis Code
          - Rules File - Yaml
          - Object Analysis Tasks
          - Object Tests
        "]
      end
      subgraph InventoryDatabase
        INVO>inv.inv_objects]
        OM[/Object Metadata/]
        OF[/Object Files/]
      end
      subgraph Billing Database 
        subgraph billing.object_health_json
          JB[/Object Build Json/]
          JA[/Object Analysis Json/]
          JT[/Object Tests Json/]
        end
      end
      subgraph OpenSearch
        OSOH[\OpenSearch Object Health Index\]
      end
      INVO-->GATHER
      OM-.->GATHER
      OF-.->GATHER
      GATHER-->BUILD
      GATHER-->ANALYZE
      GATHER-->TEST
      BUILD<-->JB
      ANALYZE<-->JA
      TEST<-->JT
      GATHER-->Publish
      Publish-->OSOH
```
