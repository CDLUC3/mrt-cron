# Collection Health Object Analysis


## Set environment (DEV)
```
export COLLHDATA=$PWD
```

## Set environment
```
export COLLHDATA=/dpr2/apps/mrt-cron/coll_health/data
cd {merrit-cron-install}/coll-health-object-analysis
```

## New Database Table
_Copy to https://github.com/CDLUC3/mrt-admin-lambda/blob/main/merrit-billing/schema.sql when complete._

```sql
/*
DROP TABLE IF EXISTS object_health_json;
*/
CREATE TABLE object_health_json (
  inv_object_id int,
  build json,
  build_updated datetime,
  analysis json,
  analysis_updated datetime,
  tests json,
  tests_updated datetime,
  UNIQUE INDEX object_id(inv_object_id)
);
```
## Install
```
bundle install
```

## Invocation
```
bundle exec ruby object_health.rb
```


## System Design

### Analysis Preparation - Initial Solution

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

### Analysis Preparation - Extended Analysis
These components will be more compuationally expensive to implement.  
The results of these analyses should feed into the existing Object Health process.

```mermaid
  graph TD;
      subgraph Object Health Publishing Process
        GATHER(Gather Objects)
      end
      subgraph InventoryDatabase
        OF[/Object Files/]
      end
      subgraph Billing Database 
        BT[/"Bitstream Test Results (future)
        - format identification
        - PII scan
        - accessiblity scan
        "/]
        AQ[/"Analysis Queries (run weekly from INV DB)
        - duplicate checksum
        - statistically unusual file size"/]
      end
      OF-.->GATHER
      BITSCAN("Bitstream Scan Process
      assumes a cloud solution will exist")
      OF-->BITSCAN
      BITSCAN-->BT
      AQC(Analysis Queries Run by Cron)
      AQC-->AQ
      OF-->AQC
      CLOUD((Cloud Storage))
      CLOUD-->BITSCAN
      BT-->GATHER
      AQ-->GATHER
```

## Interesting Open Search Queries
- `tests.FAIL > 0`
- `tests.WARN > 0`
- `build.file_counts.deleted > 0 AND build.producer.deleted: true`
- `build.file_counts.empty: 0`