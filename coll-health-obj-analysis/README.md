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
      INV_DB((Inventory Database))
      INV_DB-->Bulk_Extract;
      INV_DB-->New_Extract;
      INV_DB-->Daily_Extract;
      New_Doc[[New JSON Docs]]
      Change_log[[Change Log JSON Docs]]
      Bulk_Extract(Bulk Extract Process);
      Bulk_Extract-->New_Doc;
      New_Extract(New Object Extract Process);
      New_Extract-->New_Doc;
      Daily_Extract(Daily Extract Process);
      Daily_Extract-->Change_log;
      New_Doc-->SaveJson
      MergeUpdate(Merge and Update NoSQL Docs)
      Change_log-->MergeUpdate
      JsonRepo((JSON Repo))
      SaveJson-->JsonRepo
      MergeUpdate<-->JsonRepo
      NoSQL((NoSQL Repo))
      JsonRepo-->Publish
      Publish-->NoSQL
      NoSQLViewer(NoSQL Viewer)
      NoSQL-->NoSQLViewer
      Users[Merritt Team Member]
      Users-->NoSQLViewer
```
### Test Execution - Relational Tests
Fast, inexpensive tests, should be easy to stay up to date.  Tests may need to be re-run if the rule configration files change.
Test results are probably not worth storing in MySQL.

```mermaid
  graph TD;
      JsonRepo((JSON Repo))
      NoSQL((NoSQL Repo))
      RelationalTests(Relational Tests)
      JsonRepo<-->RelationalTests
      JsonRepo-->Publish
      Publish-->NoSQL
      TestConfig[[Test Configuration Files - Yaml]]
      TestConfig-->RelationalTests
      NoSQLViewer(NoSQL Viewer)
      NoSQL-->NoSQLViewer
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


### Test Rule Refinement
Merritt Team members will make routine changes to test configurations
- due to updates the the list of sustainable format types
- applying optional and configurable tests to specific Merritt collections

```mermaid
  graph TD;
      TestConfig[[Test Configuration Files - Yaml]]
      Puppet(Puppet Deploy)-->TestConfig
      TestConfigSrc[[Test Configuration Src]]
      Git(Git)
      TestConfigSrc-->Git
      GitHub((GitHub))
      Git<-->GitHub
      GitHub-->Puppet
      Users[Merritt Team Member]
      Users-->TestConfigSrc
```

### Annotating Object Exceptions
This tool will be created if needed.  This would provide a mechanism to record exceptional events that occurred in the life of an object or to record the conclusions of an investigation of object content.
In general, most objects should not have an annotation.  This tool would be used to prevent duplicated investigation of specific objects.

```mermaid
  graph TD;
      INV_DB((Inventory Database))
      NoSQL((NoSQL Repo))
      AnnotTool(Object Annotation Tool - Provenance Notes)
      Users-->AnnotTool
      AnnotTool--"object annotations - new table"-->INV_DB
      NoSQL-->AnnotTool
      NoSQLViewer(NoSQL Viewer)
      NoSQL-->NoSQLViewer
      Users[Merritt Team Member]
      Users-->NoSQLViewer

```

## Interesting Open Search Queries
- build.file_counts.deleted > 0 AND build.producer.deleted: true
- `build.file_counts.deleted > 0 AND build.producer.deleted: true`