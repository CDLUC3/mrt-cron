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

### Analysis Preparation

```mermaid
  graph TD;
      subgraph Object Health Publishing Process
        GATHER(Gather Objects)
        BUILD(Build Objects)
        ANALYZE(Analyze Objects)
        TEST(Test Objects)
        Publish(Publish Changes)
        subgraph code
          YAML[[Rules File - Yaml]]
          OAT(Object Analysis Tasks)
          OT(Object Tests)
        end
      end
      subgraph InventoryDatabase
        INVO>inv.inv_objects]
        OM[/Object Metadata/]
      end
      subgraph Billing Database 
        subgraph billing.object_health_json
          JB[/Object Build Json/]
          JA[/Object Analysis Json/]
          JT[/Object Tests Json/]
        end
        BT[/Bitstream Test Results/]
        AQ[/Analysis Queries/]
      end
      subgraph OpenSearch
        OSOH[\OpenSearch Object Health Index\]
      end
      INVO-->GATHER
      OM-.->GATHER
      GATHER-->BUILD
      GATHER-->ANALYZE
      GATHER-->TEST
      BUILD<-->JB
      ANALYZE<-->JA
      TEST<-->JT
      GATHER-->Publish
      Publish-->OSOH
```

### Test Execution - Bitstream Tests
Expensive tests that may need to be scheduled or prioritized. As the underlying services that perfom the operations improve, these tests should be re-run.
Because tests are expensive to execute, test results should be recoded in the inventory database.

```mermaid
  graph TD;
      INV_DB((Inventory Database))
      JsonRepo((JSON Repo))
      NoSQL((NoSQL Repo))
      BitstreamTests(Bitstream Tests)
      JsonRepo<-->BitstreamTests
      JsonRepo-->Publish
      Publish-->NoSQL
      TestConfig[[Test Configuration Files - Yaml]]
      TestConfig-->BitstreamTests
      NoSQLViewer(NoSQL Viewer)
      NoSQL-->NoSQLViewer
      Cloud((Cloud Storage))
      Cloud-->BitstreamTests
      CloudServices(Cloud Services such as PII Scan)
      OpenSrcServices(Open Source Services such as JHove or Virus Scan)
      BitstreamTests<-.->CloudServices
      BitstreamTests<-.->OpenSrcServices
      BitstreamTests--"bitstream test results - new table"-->INV_DB
```

## Interesting Open Search Queries
- `tests.FAIL > 0`
- `tests.WARN > 0`
- `build.file_counts.deleted > 0 AND build.producer.deleted: true`
- `build.file_counts.empty: 0`